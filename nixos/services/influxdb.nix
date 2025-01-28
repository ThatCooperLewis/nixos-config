{ pkgs, app, lib, user, constants, ... }:

##########################
####### InfluxDB2 ########
##########################

/*

Timeseries metrics database. Table defined via NIx.
Two quirks about this:
- The service doesn't permit custom data directories, so a symlink is necessary
- The service creates its own user, and gets upset if you override it. So only the UID/GID is set here.

*/

let
  user = "influxdb2";
  dataDir = constants.services.dirs.influxdb;
  secretsDir = "${constants.nfs.dirs.secrets.mountPath}/influxdb";
in
{

  imports = [
    ./rsync-backup.nix
  ];

  services.influxdb2 = { 
    enable = true; 
    provision = {
      enable = true;
      initialSetup = {
        username = "telegraf";
        tokenFile = "/var/lib/influxdb2/api.secret";
        passwordFile = "/var/lib/influxdb2/password.secret";
        organization = "lewis-homelab";
        bucket = "influx";
        retention = 1500001;
      };
    };
  };

  services.rsyncBackup.influxdb = {
    enable = true;
    source = dataDir;
    schedule = "05:40";
  };

  users.users.influxdb2.uid = constants.users.influxdb;
  users.groups.influxdb2.gid = constants.users.influxdb;

  networking.firewall.allowedTCPPorts = [ 8086 ];

  # Influx forces our hand for where it wants the data to be stored
  # Instead of providing a data dir, we'll just symlink it to where we want
  system.activationScripts.ensureInfluxdbDataDir = lib.mkAfter ''
    mkdir -p ${dataDir}
    cp ${secretsDir}/* ${dataDir}
    echo "telegraf" > ${dataDir}/api.secret
    chown -R ${toString constants.users.influxdb}:${toString constants.users.influxdb} ${dataDir}
    ln -sf ${dataDir} /var/lib/influxdb2
  '';
}