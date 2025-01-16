{ 
  rsyncPackage,
  backupSource,
  backupDestination,
  serviceName ? "rsyncBackup",
  schedule ? "06:00",
  user ? "root",
  group ? "root",
}:

###################################
######## Rsync Base Config ########
###################################

/*

This file is built to be imported from another configuration, with the provided args above.
The import should look like this:

  imports = [
    (import ./rsync-backup.nix {
      rsyncPackage = pkgs.rsync;                    # TODO: Make this cleaner so I don't need to import rsync directly
      backupSource      = "/path/to/sourceDir";
      backupDestination = "/path/to/destDir";
      serviceName       = "customRsyncBackup";      # Optional override
      timerName         = "customRsyncBackupTimer"; # Optional override
      schedule          = "06:00";                  # Every day at 06:00   ("*:0/10" would be every ten minutes)l
    })
  ];

*/

{

  systemd.services.${serviceName} = {
    description = "Periodic rsync backup from ${backupSource} to ${backupDestination}";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${rsyncPackage}/bin/rsync -a --delete ${backupSource}/ ${backupDestination}/";
      User = user;
      Group = group;
      SuccessExitStatus = [ 0 23 ]; # Ignore error 23
    };
  };

  systemd.timers.${serviceName} = {
    description = "Timer to trigger ${serviceName} service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = schedule;
      Persistent = true;
    };
  };
}