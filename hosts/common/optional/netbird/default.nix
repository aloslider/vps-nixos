{ config, lib, ... }:
with lib;
let
  cfg = config.vps.services.netbird;
  hostName = config.networking.hostName;
in
{
  imports = [ ./config.nix ];

  options.vps.services.netbird = {
    enable = mkEnableOption "netbird client";
  };

  config = mkIf cfg.enable {
    services.netbird.clients.${hostName} = {
      port = 51820;
      openFirewall = false;
      hardened = false;
      login = {
        enable = true;
        setupKeyFile = config.sops.secrets."netbird/setup-key".path;
      };
    };

    systemd.services."netbird-${hostName}" = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      serviceConfig.EnvironmentFile = [ config.sops.templates."netbird.env".path ];
    };

    systemd.services."netbird-${hostName}-login" = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
