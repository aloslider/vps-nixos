{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.vps.remnawave;
  script = pkgs.writeShellScript "zapret-dat-update" ''
    set -euo pipefail

    dest=/var/lib/remnanode/zapret.dat
    tmp=$(mktemp)

    trap 'rm -f "$tmp"' EXIT

    install -d -m 0755 /var/lib/remnanode

    ${pkgs.curl}/bin/curl -fsSL -o "$tmp" \
      https://github.com/kutovoys/ru_gov_zapret/releases/latest/download/zapret.dat

    changed=0
    if [[ ! -f "$dest" ]] || ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$dest"; then
      install -m 0644 "$tmp" "$dest"
      changed=1
    fi

    if [[ "''${1:-}" == --restart-if-changed && "$changed" == 1 ]] \
      && systemctl is-active --quiet docker-remnanode; then
      systemctl try-restart docker-remnanode
    fi
  '';
in
{
  config = mkIf (cfg.enable && cfg.type == "node" && cfg.zapret.enable) {
    systemd.services.zapret-dat-update = {
      description = "Download and update zapret.dat";
      wantedBy = [ "multi-user.target" ];
      before = [ "docker-remnanode.service" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig.Type = "oneshot";
      script = "${script}";
    };

    systemd.services.zapret-dat-refresh = {
      description = "Download zapret.dat and restart remnanode when it changes";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig.Type = "oneshot";
      script = "${script} --restart-if-changed";
    };

    systemd.timers.zapret-dat-refresh = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
