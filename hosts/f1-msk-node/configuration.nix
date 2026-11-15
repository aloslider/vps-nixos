{
  lib,
  modulesPath,
  ...
}:
{
  imports = lib.flatten [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./network.nix
    (map lib.custom.relativeToRoot (
      [
        "hosts/common/core"
        "hosts/common/users/benq.nix"
      ]
      ++ (map (f: "hosts/common/optional/${f}") [
        "netbird"
        "remnawave"
        "ss-zapret2"
      ])
    ))
  ];

  disko.cfg.mainDevice = "/dev/disk/by-path/pci-0000:00:07.0";

  users.users.benq.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfDJnpNXQWK55tHNzaCBzHiwxHp0LSTwkrLXPeOkPYQ benq"
  ];

  vps = {
    boot.firmware = "uefi";
    services = {
      netbird.enable = true;
      ss-zapret2 = {
        enable = true;
        socksPort = 1080;
        ssPort = 8388;
      };
    };
    remnawave = {
      enable = true;
      type = "node";
      subdomain = "f1-msk";
      zapret.enable = true;
    };
  };

  system.stateVersion = "26.11";
}
