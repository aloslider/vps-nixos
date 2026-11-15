{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.vps.remnawave;
in
{
  imports = [ ./config.nix ];

  config = mkIf (cfg.enable && cfg.type == "panel") {
    virtualisation.oci-containers.containers.remnawave-db = {
      image = "docker.io/postgres:18.1";
      autoStart = true;
      environmentFiles = [ config.sops.templates."remnawave-db.env".path ];
      volumes = [ "remnawave-db-data:/var/lib/postgresql" ];
      log-driver = "journald";
      extraOptions = [
        "--network=${cfg.panel.networkName}"
        "--hostname=remnawave-db"
        "--ulimit=nofile=1048576:1048576"
      ];
    };

    systemd.services.docker-remnawave-db = {
      after = [
        "docker-${cfg.panel.networkName}-network.service"
        "sops-nix.service"
      ];
      requires = [ "docker-${cfg.panel.networkName}-network.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
