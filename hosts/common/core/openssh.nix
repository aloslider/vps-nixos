{ config, lib, ... }:
let
  cfg = config.vps.ssh;
in
{
  options.vps.ssh = {
    public = lib.mkEnableOption "SSH on the public interface";
  };

  config = {
    services.openssh = {
      enable = cfg.public;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        PermitEmptyPasswords = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
      };
    };
  };
}
