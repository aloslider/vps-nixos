{ config, lib, ... }:
with lib;
let
  cfg = config.vps.remnawave;
in
{
  config = mkIf (cfg.enable && cfg.type == "panel") {
    sops.secrets = {
      "panel/postgres-password" = { };
    };

    sops.templates."remnawave-db.env".content = ''
      POSTGRES_USER=postgres
      POSTGRES_PASSWORD=${config.sops.placeholder."panel/postgres-password"}
      POSTGRES_DB=postgres
      TZ=UTC
    '';
  };
}
