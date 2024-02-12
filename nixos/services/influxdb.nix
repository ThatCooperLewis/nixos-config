{ pkgs, app, user, constants, ... }:

{
  config.users.users.influxdb = {
    uid = constants.users.influxdb;
    group = "influxdb";
  };
  config.users.groups.influxdb.gid = constants.users.influxdb;

  config.networking.firewall.allowedTCPPorts = [ constants.ports.influxdb ];

  config.services.influxdb = {
    enable = true;
    user = "influxdb";
    group = "influxdb";
    dataDir = "/home/influxdb/";
  };
}