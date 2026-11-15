{ config, lib, ... }:
with lib;
let
  cfg = config.vps.remnawave;
in
{
  imports = [
    ./config.nix
    ./zapret-dat.nix
    ./roscomvpn-geosite.nix
  ];

  options.vps.remnawave.node = {
    port = mkOption {
      type = types.port;
      default = 2222;
    };
    roscomvpnGeosite = mkEnableOption "roscomvpn geosite dat";
  };

  config = mkIf (cfg.enable && cfg.type == "node") {
    virtualisation.oci-containers.containers.remnanode = {
      image = "docker.io/remnawave/node:3.4.6";
      autoStart = true;
      environmentFiles = [ config.sops.templates."remnanode.env".path ];
      volumes = [
        "/dev/shm:/dev/shm"
      ]
      ++ optional cfg.zapret.enable "/var/lib/remnanode/zapret.dat:/usr/local/bin/zapret.dat:ro"
      ++ optional cfg.node.roscomvpnGeosite "/var/lib/remnanode/roscomvpn-geosite.dat:/usr/local/bin/roscomvpn-geosite.dat:ro";
      log-driver = "journald";
      extraOptions = [
        "--network=host"
        "--ulimit=nofile=1048576:1048576"
        "--cap-add=NET_ADMIN"
      ];
    };

    systemd.services.docker-remnanode = {
      after = [
        "nginx.service"
        "sops-nix.service"
      ]
      ++ optional cfg.zapret.enable "zapret-dat-update.service"
      ++ optional cfg.node.roscomvpnGeosite "roscomvpn-geosite-update.service";
      wants = [
        "sops-nix.service"
      ]
      ++ optional cfg.zapret.enable "zapret-dat-update.service"
      ++ optional cfg.node.roscomvpnGeosite "roscomvpn-geosite-update.service";
      serviceConfig.LimitNOFILE = 1048576;
    };
  };
}
