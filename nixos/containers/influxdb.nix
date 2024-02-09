{ config, constants, ...}:

let
  docker = constants.docker;
in
{
  config.networking.firewall.allowedTCPPorts = [ constants.ports.influxdb ];
  config.virtualisation.oci-containers.containers = {
    influxdb = {
      image = "influxdb:1.8";
      ports = docker.ports.influxdb;
      environment = {
      	PUID = docker.users.tig;
      	PGID = docker.users.tig;
      	INFLUX_DB = "influx";
      	INFLUXDB_ADMIN_USER = "admin";
      	INFLUXDB_ADMIN_PASSWORD = "admin";
      };
      volumes = [ "${docker.dirs.tig}/influxdb/data:/var/lib/influxdb" ];
    };
  };
}