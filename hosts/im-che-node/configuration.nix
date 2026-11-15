{
  config,
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

  vps.boot.firmware = "bios";

  users.users.benq.openssh.authorizedKeys.keys = lib.mkForce [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMXDyLwKBc7knfnU5BWXYkxkxVupF6VTPu2knOOgCeY benq"
  ];

  vps = {
    services.netbird.enable = true;
    remnawave = {
      enable = true;
      type = "node";
      subdomain = "im-che";
      node.roscomvpnGeosite = true;
    };
  };

  system.stateVersion = "26.11";
}
