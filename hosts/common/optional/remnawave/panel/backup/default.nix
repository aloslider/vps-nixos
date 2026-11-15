{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  rootCfg = config.vps.remnawave;
in
{
  imports = [ ./config.nix ];

  options.vps.remnawave.panel.backup = {
    enable = mkEnableOption "Enable panel backups";
  };

  config = mkIf (rootCfg.panel.backup.enable && rootCfg.type == "panel") {
    systemd.services.remnawave-backup = {
      description = "Dump the panel database and send it out";
      after = [
        "docker-remnawave-db.service"
        "network-online.target"
      ];
      wants = [ "docker-remnawave-db.service" ];
      path = [ pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates."remnawave-backup.env".path;
        ExecStart = pkgs.writeShellScript "remnawave-backup" ''
          set -eu

          stamp=$(date -u +%Y%m%dT%H%M%SZ)
          dir=/var/lib/remnawave-backup
          out="$dir/remnawave-$stamp.sql.gz"

          install -d -m 0700 "$dir"

          ${pkgs.docker}/bin/docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" remnawave-db \
            pg_dump -U postgres postgres | ${pkgs.gzip}/bin/gzip -c > "$out"
          chmod 0600 "$out"

          if [ -n "''${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "''${TELEGRAM_CHAT_ID:-}" ]; then
            ${pkgs.curl}/bin/curl -fsS \
              -F "chat_id=$TELEGRAM_CHAT_ID" \
              -F "document=@$out" \
              "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
              || echo "telegram backup upload failed" >&2
          fi

          if [ -n "''${BACKUP_SSH_TARGET:-}" ]; then
            ${pkgs.openssh}/bin/scp \
              -i ${config.sops.secrets."panel/backup-ssh-key".path} \
              -o StrictHostKeyChecking=accept-new \
              "$out" "$BACKUP_SSH_TARGET" \
              || echo "netbird backup copy failed" >&2
          fi

          ls -1t "$dir"/remnawave-*.sql.gz | tail -n +8 | xargs -r rm -f
        '';
      };
    };

    systemd.timers.remnawave-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    systemd.tmpfiles.rules = [ "d /var/lib/remnawave-backup 0700 root root -" ];
  };
}
