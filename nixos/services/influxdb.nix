{ pkgs, app, lib, user, constants, ... }:

let
  user = "influxdb2";
  dataDir = constants.services.dirs.influxdb;
  secretPath = "/var/lib/influxdb2/telegraf.secret";
in
{
  services.influxdb2 = { 
    enable = true; 
    provision = {
      enable = true;
      initialSetup = {
        username = "telegraf";
        tokenFile = secretPath;
        passwordFile = secretPath;
        organization = "lewis-homelab";
        bucket = "influx";
        retention = 1500000;
      };
    };
  };

  users.users.influxdb2.uid = constants.users.influxdb;
  users.groups.influxdb2.gid = constants.users.influxdb;

  networking.firewall.allowedTCPPorts = [ 8086 ];

  # Influx forces our hand for where it wants the data to be stored
  # Instead of providing a data dir, we'll just symlink it to where we want
  # Remove the original dir, but only if it hasn't been symlinked already
  system.activationScripts.ensureInfluxdbDataDir = lib.mkAfter ''
    mkdir -p ${dataDir}
    echo "telegraf" > ${dataDir}/telegraf.secret
    chown -R ${toString constants.users.influxdb}:${toString constants.users.influxdb} ${dataDir}
    
    if [ -d /var/lib/influxdb2 ] && [ ! -L /var/lib/influxdb2 ]; then
        sudo rm -rf /var/lib/influxdb2
    fi
    
    ln -s ${dataDir} /var/lib/influxdb2
  '';
}