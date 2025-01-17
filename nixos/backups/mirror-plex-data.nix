{ config, pkgs, constants, ... }:

{
  imports = [
    ../storage/nas-plex.nix

    (import ./rsync-base.nix {
      rsyncPackage      = pkgs.rsync;
      backupSource      = "${constants.nfs.dirs.plex.mountPath}";
      backupDestination = "${constants.services.dirs.plexMirror}";
      serviceName       = "plexDataMirroring";
      schedule          = "*:0/10";
    })
  ];
}