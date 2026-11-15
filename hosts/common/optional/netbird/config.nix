{ config, lib, ... }:
with lib;
let
  cfg = config.vps.services.netbird;
in
{
  config = mkIf cfg.enable {
    sops.secrets = {
      "netbird/setup-key" = { };
      "netbird/management-url" = { };
    };

    sops.templates."netbird.env".content = ''
      NB_MANAGEMENT_URL=${config.sops.placeholder."netbird/management-url"}
    '';
  };
}
