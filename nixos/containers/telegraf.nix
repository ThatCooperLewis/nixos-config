{ config, constants, ...}:

let
  docker = constants.docker;
in
{
  config.networking.firewall.allowedTCPPorts = [ constants.ports.telegraf ];
  config.virtualisation.oci-containers.containers = {
    telegraf = {
      image = "telegraf:latest";
      ports = docker.ports.telegraf;
      environment = {
        PUID = docker.users.telegraf;
        PGID = docker.users.telegraf;
        
        INFLUXDB_URL = constants.urls.influxdb;
        INFLUXDB_DATABASE = "influx";
        INFLUXDB_USER = "telegraf";
        INFLUXDB_PW = "metricsmetricsmetricsmetrics";

        PLEX_URL = constants.urls.plex;
        TDARR_URL = constants.urls.tdarr;
        OVERSEERR_URL = constants.urls.overseerr;
        SAB_URL = constants.urls.sab;
        RADARR_URL = constants.urls.radarr;
        SONARR_URL = constants.urls.sonarr;
        HOME_ASS_URL = constants.urls.ha;
      };
      volumes = [ "${docker.dirs.telegraf}/telegraf.conf:/etc/telegraf/telegraf.conf:ro" ];
    };
  };
}