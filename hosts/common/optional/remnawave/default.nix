{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.vps.remnawave;
  targetName = "remnawave.target";
  remnaService =
    if cfg.type == "node" then
      "docker-remnanode.service"
    else if cfg.type == "panel" then
      "docker-remnapanel.service"
    else
      throw "Unknown remnawave type ${cfg.type}";
  units = [
    "nginx.service"
    remnaService
  ]
  ++ optionals (cfg.type == "panel") [
    "docker-remnawave-db.service"
    "docker-remnawave-valkey.service"
    "docker-remnawave-subpage.service"
    "docker-tinyauth.service"
  ]
  ++ optional cfg.zapret.enable "docker-ss-zapret2.service";
in
{
  imports = [
    ./node
    ./panel
  ];

  options.vps.remnawave = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    type = mkOption {
      type = types.enum [
        "node"
        "panel"
      ];
    };
    subdomain = mkOption {
      type = types.str;
    };
    zapret.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    systemd.targets.remnawave = {
      description = "Remnawave ${cfg.type} stack";
      wants = units;
      after = units;
    };

    systemd.services.nginx.partOf = [ targetName ];
    systemd.services.docker-remnanode.partOf = mkIf (cfg.type == "node") [ targetName ];
    systemd.services.docker-remnapanel.partOf = mkIf (cfg.type == "panel") [ targetName ];
    systemd.services.docker-remnawave-db.partOf = mkIf (cfg.type == "panel") [ targetName ];
    systemd.services.docker-remnawave-valkey.partOf = mkIf (cfg.type == "panel") [ targetName ];
    systemd.services.docker-remnawave-subpage.partOf = mkIf (cfg.type == "panel") [ targetName ];
    systemd.services.docker-tinyauth.partOf = mkIf (cfg.type == "panel") [ targetName ];
    systemd.services.docker-ss-zapret2.partOf = mkIf cfg.zapret.enable [ targetName ];
  };
}
