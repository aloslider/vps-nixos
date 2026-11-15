{ config, lib, pkgs, ... }:
with lib;
let
  moduleCfg = config.vps.services.ss-zapret2;
in
{
  imports = [ ./config.nix ];

  options.vps.services.ss-zapret2 = {
    enable = mkEnableOption "Enable ss-zapret2";
    config = mkOption {
      type = types.path;
    };
    socksPort = mkOption {
      type = types.port;
      default = 1080;
    };
    ssPort = mkOption {
      type = types.port;
      default = 8388;
    };
  };

  config = mkIf moduleCfg.enable {
    virtualisation.oci-containers.containers.ss-zapret2 = {
      image = "docker.io/vernette/ss-zapret2:v1.0.2";
      environmentFiles = [ config.sops.templates."ss-zapret2.env".path ];
      volumes = [
        "${moduleCfg.config}:/opt/zapret2/config"
        "${./lists}:/opt/lists"
        "/var/lib/ss-zapret2/lua:/opt/zapret2/lua"
        "/var/lib/ss-zapret2/fakes:/opt/zapret2/files/fake"
      ];
      ports = [
        "127.0.0.1:${toString moduleCfg.ssPort}:${toString moduleCfg.ssPort}"
        "127.0.0.1:${toString moduleCfg.socksPort}:${toString moduleCfg.socksPort}"
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--ulimit" "nofile=32768:65536"
      ];
    };

    systemd.services.docker-ss-zapret2 = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
      path = with pkgs; [ 
        coreutils 
        curl 
      ];
      preStart = ''
        dir=/var/lib/ss-zapret2/fakes
        base=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/bin
        mkdir -p "$dir"

        # download any missing/empty fake file from flowseal's bin/ folder
        for f in \
          tls_clienthello_www_google_com.bin \
          quic_initial_www_google_com.bin \
          tls_clienthello_www_sferum_ru.bin \
          tls_clienthello_max_ru.bin \
          tls_clienthello_4pda_to.bin \
          stun.bin
        do
          if [ ! -s "$dir/$f" ]; then
            echo "downloading $f"
            curl -fsSL --retry 3 -o "$dir/$f.tmp" "$base/$f"
            mv "$dir/$f.tmp" "$dir/$f"
          fi
        done
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/ss-zapret2/lua 0755 root root -"
      "d /var/lib/ss-zapret2/fakes 0755 root root -"
    ];
  };
}
