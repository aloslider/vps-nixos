{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  rootCfg = config.vps.remnawave;
  letsencryptScript = pkgs.writeShellScript "letsencrypt-wildcard" ''
    set -eu

    install -d -m 0755 /var/lib/certs/live
    install -d -m 0700 /var/lib/lego

    lego run \
      --accept-tos \
      --email "$LEGO_EMAIL" \
      --dns porkbun \
      --path /var/lib/lego \
      --domains "*.$DOMAIN" \
      --renew-days 30

    install -m 0644 "/var/lib/lego/certificates/_.$DOMAIN.crt" /var/lib/certs/live/fullchain.pem
    install -m 0640 -g nginx "/var/lib/lego/certificates/_.$DOMAIN.key" /var/lib/certs/live/privkey.pem

    if [ -s /run/nginx/nginx.pid ] && kill -0 "$(cat /run/nginx/nginx.pid)" 2>/dev/null; then
      ${pkgs.nginx}/bin/nginx -s reload
    fi
  '';
in
{
  imports = [ ./config.nix ];

  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    environment.systemPackages = [ pkgs.lego ];

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      sslProtocols = "TLSv1.2 TLSv1.3";
      appendHttpConfig = ''
        include ${config.sops.templates."nginx.conf".path};
      '';
    };

    systemd.services.nginx = {
      after = [
        "sops-nix.service"
        "letsencrypt-wildcard.service"
        "docker-tinyauth.service"
        "docker-remnapanel.service"
        "docker-remnawave-subpage.service"
      ];
      requires = [ "letsencrypt-wildcard.service" ];
      wants = [
        "sops-nix.service"
        "docker-tinyauth.service"
        "docker-remnapanel.service"
        "docker-remnawave-subpage.service"
      ];
    };

    systemd.services.letsencrypt-wildcard = {
      description = "Issue a wildcard certificate for domain";
      requiredBy = [ "nginx.service" ];
      before = [ "nginx.service" ];
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [
        "network-online.target"
        "sops-nix.service"
      ];
      path = with pkgs; [
        coreutils
        lego
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = config.sops.templates."letsencrypt.env".path;
        ExecStart = letsencryptScript;
      };
    };

    systemd.services.letsencrypt-wildcard-renew = {
      description = "Renew a wildcard certificate";
      after = [
        "network-online.target"
        "sops-nix.service"
        "letsencrypt-wildcard.service"
      ];
      wants = [
        "network-online.target"
        "sops-nix.service"
      ];
      path = with pkgs; [
        coreutils
        lego
      ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates."letsencrypt.env".path;
        ExecStart = letsencryptScript;
      };
    };

    systemd.timers.letsencrypt-wildcard-renew = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "60d";
        OnUnitActiveSec = "60d";
        Persistent = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/certs/live 0755 root root -"
      "d /var/lib/lego 0700 root root -"
    ];
  };
}
