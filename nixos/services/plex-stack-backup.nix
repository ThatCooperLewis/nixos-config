{ config, pkgs, constants, ... }:

let
  backupSource = "${constants.nuc.dirs.plexStack}";
  backupDestination = "${constants.nuc.dirs.plexStackBackup}";
in {

  # Define the service
  systemd.services.rsyncBackup = {
    description = "Periodic rsync backup of the Plex stack";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.rsync}/bin/rsync -a --delete ${backupSource}/ ${backupDestination}/";
      User = "root";  # Ensures it runs as root
      Group = "root"; # Ensures it runs as root
      SuccessExitStatus = [ 0 23 ]; # Error 23 should be ignored (some files couldn't be copied)
    };
  };

  # Define the timer
  systemd.timers.rsyncBackup = {
    description = "Timer to trigger the rsync backup service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "06:00"; # Runs at 6:00 AM every day
      Persistent = true;
    };
  };
}