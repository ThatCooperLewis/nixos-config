{ config, pkgs, constants, ... }:

{
  imports = [
    (import ./rsync-base.nix {
      rsyncPackage = pkgs.rsync;
      backupSource = "${constants.nuc.dirs.plexStack}";
      backupDestination = "${constants.nuc.dirs.plexStackBackup}";
      serviceName       = "arrRsyncBackup";
      schedule          = "06:00";
    })
  ];
}