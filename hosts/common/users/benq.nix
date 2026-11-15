{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets."users/root/password".neededForUsers = true;
  sops.secrets."users/benq/password".neededForUsers = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel") && action.id.indexOf("org.freedesktop.systemd1.") == 0) {
        return polkit.Result.YES;
      }
    });
  '';

  users = {
    mutableUsers = false;
    users.root.hashedPasswordFile = config.sops.secrets."users/root/password".path;
    users.benq = {
      isNormalUser = true;
      uid = 1000;
      shell = pkgs.bash;
      hashedPasswordFile = config.sops.secrets."users/benq/password".path;
      extraGroups = [
        "docker"
        "systemd-journal"
        "wheel"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/benq 0755 benq users -"
    "d /home/benq/.config 0755 benq users -"
    "d /home/benq/.config/sops 0700 benq users -"
    "L+ /home/benq/.sops.yaml - - - - ${lib.custom.relativeToRoot ".sops.yaml"}"
  ];
}
