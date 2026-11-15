{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  rootCfg = config.vps.remnawave;
  moduleCfg = rootCfg.panel;
in
{
  imports = [ ./config.nix ];

  options.vps.remnawave.panel = {
    subdomain = mkOption {
      type = types.str;
      default = "panel";
    };
    networkName = mkOption {
      type = types.str;
      default = "remnawave";
    };
    appPort = mkOption {
      type = types.port;
      default = 3000;
    };
    metricsPort = mkOption {
      type = types.port;
      default = 3001;
    };
  };

  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    virtualisation.oci-containers.containers.remnapanel = {
      image = "docker.io/remnawave/backend:3.4.11";
      autoStart = true;
      environmentFiles = [ config.sops.templates."remnapanel.env".path ];
      ports = [ "127.0.0.1:${toString moduleCfg.appPort}:${toString moduleCfg.appPort}" ];
      log-driver = "journald";
      extraOptions = [
        "--network=${moduleCfg.networkName}"
        "--hostname=remnapanel"
        "--ulimit=nofile=1048576:1048576"
      ];
    };

    systemd.services.docker-remnawave-network = {
      description = "Create the remnawave docker network";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if ! ${pkgs.docker}/bin/docker network inspect ${moduleCfg.networkName} >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network create ${moduleCfg.networkName}
        fi
      '';
    };

    systemd.services.docker-remnapanel = {
      after = [
        "docker-${moduleCfg.networkName}-network.service"
        "docker-remnawave-db.service"
        "docker-remnawave-valkey.service"
        "sops-nix.service"
      ];
      requires = [
        "docker-${moduleCfg.networkName}-network.service"
        "docker-remnawave-db.service"
        "docker-remnawave-valkey.service"
      ];
      wants = [ "sops-nix.service" ];
      serviceConfig.LimitNOFILE = 1048576;
    };
  };
}
