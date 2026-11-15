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
      ])
    ))
  ];

  disko.cfg.mainDevice = "/dev/disk/by-path/pci-0000:00:04.0-scsi-0:0:0:0";

  users.users.benq.openssh.authorizedKeys.keys = lib.mkForce [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOAIQmHVpVGTgFVQybOJuMBvtR8OQv5Ql1e9YeyZiKYR benq"
  ];

  vps = {
    boot.firmware = "bios";
    services.netbird.enable = true;
    remnawave = {
      enable = true;
      type = "panel";
      subdomain = "panel";
      panel.backup.enable = false;
    };
  };

  system.stateVersion = "26.11";
}
