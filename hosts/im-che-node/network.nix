{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  networking.hostName = "im-che-node";
  networking.useNetworkd = true;
  networking.useDHCP = false;
  networking.firewall = {
    trustedInterfaces = [ "nb-${config.networking.hostName}" ];
    checkReversePath = "loose";
    allowedTCPPorts = [
      80
      443
    ]
    ++ optional config.vps.ssh.public 22;
    allowedUDPPorts = [ 443 ];
  };

  vps.ssh.public = true;

  boot.tcp-brutal.enable = true;

  sops.secrets = {
    "network/ipv4" = { };
    "network/gateway" = { };
    "network/ipv6" = { };
    "network/gateway6" = { };
  };

  sops.templates."10-ens3.network".content = ''
    [Match]
    Name=ens3

    [Network]
    Address=${config.sops.placeholder."network/ipv4"}/24
    Address=${config.sops.placeholder."network/ipv6"}/128
    DNS=1.1.1.1
    DNS=8.8.8.8

    [Route]
    Gateway=${config.sops.placeholder."network/gateway"}
    GatewayOnLink=yes

    [Route]
    Gateway=${config.sops.placeholder."network/gateway6"}
    GatewayOnLink=yes
    '';

  systemd.services.copy-ens3-network = {
    description = "Install decrypted ens3 networkd unit";
    wantedBy = [ "network-pre.target" ];
    requiredBy = [ "sysinit-reactivation.target" ];
    before = [
      "systemd-networkd.service"
      "systemd-networkd-wait-online.service"
      "network-pre.target"
      "sysinit-reactivation.target"
    ];
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    path = [
      pkgs.coreutils
      pkgs.systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0755 /run/systemd/network
      install -m 0644 ${config.sops.templates."10-ens3.network".path} /run/systemd/network/10-ens3.network
      if systemctl is-active --quiet systemd-networkd; then
        networkctl reload
        networkctl reconfigure ens3
      fi
    '';
  };
}
