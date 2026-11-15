{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.vps.services.tg-ws-proxy;

  tgSrc = pkgs.fetchFromGitHub {
    owner = "Flowseal";
    repo = "tg-ws-proxy";
    rev = "v1.11.4";
    hash = "sha256-N7k8D2tnO4iVFq5lXjhdKpYMR+gDsCkKZLTpACpJStY=";
  };

  py = pkgs.python312.withPackages (ps: [
    ps.cryptography
    ps.certifi
    ps.httpx
    ps.h2
  ]);

  app = pkgs.runCommand "tg-ws-proxy-app" { } ''
    mkdir -p $out/app
    cp -r ${tgSrc}/proxy ${tgSrc}/utils $out/app/
  '';

  entry = pkgs.writeShellScriptBin "tg-ws-proxy-entry" ''
    set -eu

    args="--host ''${TG_WS_PROXY_HOST} --port ''${TG_WS_PROXY_PORT}"

    for dc in ''${TG_WS_PROXY_DC_IPS}; do
      args="$args --dc-ip $dc"
    done

    if [ -n "''${TG_WS_PROXY_SECRET}" ]; then 
      args="$args --secret ''${TG_WS_PROXY_SECRET}"; 
    fi

    if [ -n "''${TG_WS_PROXY_CF_WORKER}" ]; then 
      args="$args --cfproxy-worker-domain ''${TG_WS_PROXY_CF_WORKER}"; 
    fi

    if [ "''${TG_WS_PROXY_NO_SECURE}" = "True" ]; then 
      args="$args --no-secure"; 
    fi

    exec ${py}/bin/python -u /app/proxy/tg_ws_proxy.py $args "$@"
  '';

  tgImage = pkgs.dockerTools.buildLayeredImage {
    name = "tg-ws-proxy";
    tag = "local";
    contents = [
      entry
      app
      pkgs.cacert
    ];
    config = {
      Entrypoint = [ "${entry}/bin/tg-ws-proxy-entry" ];
      WorkingDir = "/app";
      User = "65534:65534";
      ExposedPorts."1443/tcp" = { };
      Env = [
        "PYTHONDONTWRITEBYTECODE=1"
        "PYTHONUNBUFFERED=1"
        "PYTHONPATH=/app"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TG_WS_PROXY_HOST=0.0.0.0"
        "TG_WS_PROXY_PORT=1443"
        "TG_WS_PROXY_SECRET="
        "TG_WS_PROXY_DC_IPS=2:149.154.167.220 4:149.154.167.220"
        "TG_WS_PROXY_CF_WORKER="
        "TG_WS_PROXY_NO_SECURE=False"
      ];
    };
  };
in
{
  imports = [
    ./config.nix
  ];

  options.vps.services.tg-ws-proxy = {
    enable = mkEnableOption "Enable tg-ws-proxy";
    port = mkOption {
      type = types.port;
      default = 1443;
    };
  };

  config = {

    virtualisation.oci-containers.containers.tg-ws-proxy = {
      image = "tg-ws-proxy:local";
      imageFile = tgImage;
      environmentFiles = [ config.sops.templates."tg-ws-proxy.env".path ];
      ports = [ 
        "127.0.0.1:${toString cfg.port}:1443" 
      ];
    };

    systemd.services.docker-tg-ws-proxy = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };
  };
}
