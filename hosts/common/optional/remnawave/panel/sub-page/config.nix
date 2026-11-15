{ config, lib, ... }:
with lib;
let
  rootCfg = config.vps.remnawave;
  moduleCfg = rootCfg.panel.sub-page;
in
{
  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    sops.secrets = {
      "panel/subpage-api-token" = { };
    };

    sops.templates."remnawave-subpage.env".content = ''
      REMNAWAVE_PANEL_URL=http://remnapanel:3000
      APP_PORT=${toString moduleCfg.port}
      TRUST_PROXY=1
      REMNAWAVE_API_TOKEN=${config.sops.placeholder."panel/subpage-api-token"}
    '';
  };
}
