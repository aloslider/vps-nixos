{ ... }:
{
  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      daemon.settings = {
        log-driver = "journald";
      };
    };
  };

  services.journald.settings.Journal.SystemMaxUse = "200M";
}
