{
  config,
  lib,
  ...
}:
with lib;
let
  firmware = config.vps.boot.firmware;
in
{
  options.vps.boot.firmware = mkOption {
    type = types.enum [
      "uefi"
      "bios"
    ];
  };

  config = {
    zramSwap.enable = true;

    boot.loader = 
      if firmware == "uefi" then {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = false;
      } 
      else if firmware == "bios" then {
        grub.enable = true;
      }
      else throw "Unknown boot firmware type";
  };
}
