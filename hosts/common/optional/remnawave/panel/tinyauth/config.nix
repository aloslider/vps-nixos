{ config, lib, ... }:
with lib;
let
  rootCfg = config.vps.remnawave;
  moduleCfg = rootCfg.panel.auth;
  domain = config.sops.placeholder."domain";
in
{
  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    sops.secrets = {
      "domain" = { };
      "panel/tinyauth-users" = { };
    };

    sops.templates."tinyauth.env".content = ''
      TINYAUTH_SERVER_PORT=${toString moduleCfg.port}
      TINYAUTH_APPURL=https://${moduleCfg.subdomain}.${domain}
      TINYAUTH_AUTH_USERS=${config.sops.placeholder."panel/tinyauth-users"}
    '';
  };
}
