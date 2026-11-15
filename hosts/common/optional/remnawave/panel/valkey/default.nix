{
  config,
  lib,
  ...
}:
with lib;
let
  rootCfg = config.vps.remnawave;
in
{
  options.vps.remnawave.panel.redis = {
    port = mkOption {
      type = types.port;
      default = 6379;
    };
  };

  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    virtualisation.oci-containers.containers.remnawave-valkey = {
      image = "docker.io/valkey/valkey:9.0.0-alpine";
      autoStart = true;
      cmd = [
        "valkey-server"
        "--save"
        ""
        "--appendonly"
        "no"
        "--maxmemory-policy"
        "noeviction"
        "--loglevel"
        "warning"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${rootCfg.panel.networkName}"
        "--hostname=remnawave-valkey"
        "--ulimit=nofile=1048576:1048576"
      ];
    };

    systemd.services.docker-remnawave-valkey = {
      after = [ "docker-${rootCfg.panel.networkName}-network.service" ];
      requires = [ "docker-${rootCfg.panel.networkName}-network.service" ];
    };
  };
}
