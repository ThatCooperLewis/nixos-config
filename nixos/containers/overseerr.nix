{ config, pkgs, constants, ... }:

##########################
####### OVERSEERR ########
##########################

/*

Separating the public requests site from the NUC's plex stack, so it can be isolated from the rest of the network

Backups are pulled by the NAS (TrueNAS Rsync Task "fortress-pi overseerr"), so this machine never mounts NAS shares.
The nas-backup user's key only allows read-only rsync of dataDir.

*/

let

  dataDir = "/var/lib/overseerr";
  docker = constants.docker;
  # Public half of TrueNAS keychain credential "fortress-pi-backup"
  nasBackupKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDpRouSc27wJuVlAfzWMax2oZ72IDTCdDlIgoLM1+SQp8oGh/NITnPastyRkOULJT6TrCC0YM5R+a4OhSUDa+IE6RoQtdztCMYUicO2E7vOPi/hvHqrNGShXmglwaPjuFg1WlGRjUFOD+j4gWog9QX2ZsCE//Ye6/fsBElJwbou3n2DfDyLMv6rwE3nOpR4zIIkklKGpG7THvU+Ew0AVJ8RvNOUaBtYi099QpTnQEVz2BkC1tmUZdsRe6fOvsofpBcYrvBPLXBg/S3B6ITQwUWUnxnuDSwhEYazD2lzTqvILjb1i2+EBz/LymPPaM+n/OeCCDmqSGtp2iZZ73ZEVOUCdvaWZRU2+Ym/0jqVwAsZGZWNltNw5QMD6rjLtCyTn2RqM3WiuX23nw1z3G8uu9kAV2v/D7wv6Ovr3gRTQCOkRrvz4Q7hwF8li4JA32wS30m1nm/fpRq/uoE9KlLSK7XdmM3Q7oeyhyE5MK3XastwHOoHGX6QzC+MeaZUg5QiGwU= truenas";
in {

  imports = [
    ./container-base.nix
  ];

  networking.firewall.allowedTCPPorts = [ constants.ports.overseerr ];
  users.users.overseerr = {
    uid = constants.users.multimedia;
    description = "Overseerr";
    isSystemUser = true;
    group = "overseerr";
    extraGroups = [ "wheel" ];
  };
  users.groups.overseerr.gid = constants.users.multimedia;

  # Read-only login for the NAS to pull backups
  environment.systemPackages = [ pkgs.rsync ];
  users.users.nas-backup = {
    isSystemUser = true;
    group = "nas-backup";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      ''command="${pkgs.rrsync}/bin/rrsync -ro ${dataDir}",restrict ${nasBackupKey}''
    ];
  };
  users.groups.nas-backup = {};

  virtualisation.oci-containers.containers.overseerr = {
    image = "ghcr.io/hotio/overseerr";
    ports = docker.ports.overseerr;
    environment = docker.environment;
    volumes = [
      "/var/lib/overseerr:/config"
    ];
  };
}
    
    