{ config, lib, ... }:
with lib;
let
  cfg = config.vps.remnawave;
in
{
  config = mkIf (cfg.enable && cfg.type == "node") {
    sops.secrets = {
      "remnanode/secret-key" = { };
    };

    sops.templates."remnanode.env".content = ''
      NODE_PORT=${toString cfg.node.port}
      SECRET_KEY=${config.sops.placeholder."remnanode/secret-key"}
      CUSTOM_CORE_URL=https://github.com/Jolymmiles/Xray-core/releases/download/v26.11.10-1249/Xray-linux-64
    '';
  };
}
