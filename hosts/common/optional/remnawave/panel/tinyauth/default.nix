{ config, lib, ... }:
with lib;
let
  rootCfg = config.vps.remnawave;
  moduleCfg = rootCfg.panel.auth;
in
{
  imports = [ ./config.nix ];

  options.vps.remnawave.panel.auth = {
    subdomain = mkOption {
      type = types.str;
      default = "auth";
    };
    port = mkOption {
      type = types.port;
      default = 3002;
    };
  };

  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    virtualisation.oci-containers.containers.tinyauth = {
      image = "ghcr.io/maposia/remnawave-tinyauth:v5";
      autoStart = true;
      environmentFiles = [ config.sops.templates."tinyauth.env".path ];
      ports = [ "127.0.0.1:3002:${toString moduleCfg.port}" ];
      volumes = [ "tinyauth-data:/data" ];
      log-driver = "journald";
      extraOptions = [
        "--network=${rootCfg.panel.networkName}"
        "--hostname=tinyauth"
      ];
    };

    systemd.services.docker-tinyauth = {
      after = [
        "docker-${rootCfg.panel.networkName}-network.service"
        "sops-nix.service"
      ];
      requires = [ "docker-${rootCfg.panel.networkName}-network.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
