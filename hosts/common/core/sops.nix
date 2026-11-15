{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = lib.custom.relativeToRoot "hosts/${config.networking.hostName}/secrets.yaml";
    age.keyFile = "/etc/age/key.txt";
    validateSopsFiles = false;
  };
}
