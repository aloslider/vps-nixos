{
  config,
  disko,
  lib,
  ...
}:
with lib;
let
  cfg = config.disko.cfg;
in
{
  imports = [
    disko.nixosModules.disko
  ];

  options.disko.cfg = {
    mainDevice = mkOption {
      type = types.str;
      description = "Main disk name";
    };
  };

  config = {
    disko.devices.disk.main = {
      device = cfg.mainDevice;
      type = "disk";
      content = {
        type = "gpt";
        partitions =
          let
            swap = {
              size = "4G";
              priority = 2000;
              content.type = "swap";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "noatime" ];
              };
            };
          in
          if config.vps.boot.firmware == "uefi" then
            {
              ESP = {
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              inherit swap root;
            }
          else
            {
              boot = {
                size = "1M";
                type = "EF02";
              };
              inherit swap root;
            };
      };
    };
  };
}
