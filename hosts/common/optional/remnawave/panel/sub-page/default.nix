{ config, lib, ... }:
with lib;
let
  rootCfg = config.vps.remnawave;
  moduleCfg = rootCfg.panel.sub-page;
in
{
  imports = [ ./config.nix ];

  options.vps.remnawave.panel.sub-page = {
    subdomain = mkOption {
      type = types.str;
      default = "sub";
    };
    port = mkOption {
      type = types.port;
      default = 3010;
    };
  };

  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    virtualisation.oci-containers.containers.remnawave-subpage = {
      image = "docker.io/remnawave/subscription-page:8.0.1";
      autoStart = true;
      environmentFiles = [ config.sops.templates."remnawave-subpage.env".path ];
      ports = [ "127.0.0.1:3010:${toString moduleCfg.port}" ];
      log-driver = "journald";
      extraOptions = [
        "--network=${rootCfg.panel.networkName}"
        "--hostname=remnawave-subpage"
        "--ulimit=nofile=1048576:1048576"
      ];
    };

    systemd.services.docker-remnawave-subpage = {
      after = [
        "docker-${rootCfg.panel.networkName}-network.service"
        "docker-remnapanel.service"
        "sops-nix.service"
      ];
      requires = [ "docker-${rootCfg.panel.networkName}-network.service" ];
      wants = [
        "docker-remnapanel.service"
        "sops-nix.service"
      ];
    };
  };
}
