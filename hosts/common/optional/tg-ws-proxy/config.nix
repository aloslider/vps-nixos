{ config, lib, ... }:
with lib;
let
  cfg = config.vps.services.tg-ws-proxy;
in
{
  config = mkIf cfg.enable {
    sops.secrets = {
      "tg-ws-proxy/secret" = { };
    };

    sops.templates."tg-ws-proxy.env".content = ''
      TG_WS_PROXY_SECRET=${config.sops.placeholder."tg-ws-proxy/secret"}
    '';
  };
}
