{ config, pkgs, lib, ... }:

let

  tigConfigDir = "/home/cooper/tig-stack";
  kumaConfigDir = "/home/cooper/uptime-stack";

  ports = {
  	influxdb = 8086;
  	telegraf = 8125;
  	grafana = 3000;
  	uptimeKuma = 3001;
  };

  dockerPorts = {
  	influxdb = ["${toString ports.influxdb}:${toString ports.influxdb}"];
  	telegraf = ["${toString ports.telegraf}:${toString ports.telegraf}"];
  	grafana = ["${toString ports.grafana}:${toString ports.grafana}"];
  	uptimeKuma = ["${toString ports.uptimeKuma}:${toString ports.uptimeKuma}"];
  };

in {
# {
  config.networking.firewall = {
    enable = true;
    allowedTCPPorts = lib.attrValues ports;
    interfaces.docker1 = {
      # Allow ports to query each other
      allowedUDPPorts = [ 53 ];
    };
  };

    # Install docker
  config.virtualisation.docker = {
  	enable = true;
  	enableOnBoot = true;
  	rootless = {
  	  enable = true;
  	  setSocketVariable = true;	
  	};
  };

  config.virtualisation.oci-containers.backend = "docker";

  # Create a shared network so containers can talk to each other
  config.systemd.services.create-tig-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ 
      "${backend}-influxdb.service" 
      # "${backend}-grafana.service"
      # "${backend}-telegraf.service" 
    ];
    script = ''${pkgs.docker}/bin/docker network create --driver bridge tig-stack || true'';
  };

  config.virtualisation.oci-containers.containers = {

    # influxdb = {
    #   image = "influxdb:1.8";
    #   ports = dockerPorts.influxdb;
    #   environment = {
    #   	PUID = "950";
    #   	PGID = "950";
    #   	INFLUX_DB = "influx";
    #   	INFLUXDB_ADMIN_USER = "admin";
    #   	INFLUXDB_ADMIN_PASSWORD = "admin";
    #   };
    #   volumes = [ "${tigConfigDir}/influxdb/data:/var/lib/influxdb" ];
    # };

    # telegraf = {
    #   image = "telegraf:latest";
    #   ports = dockerPorts.telegraf;
    #   environment = {
    #     PUID = "950";
    #     PGID = "950";
    #     PRIMARY_IP = "http://10.0.50.1";
    #     PLEX_PORT = "32400";
    #     TDARR_PORT = "8265";
    #     OVERSEERR_PORT = "5055";
    #     NZBGET_PORT = "6789";
    #     RADARR_PORT = "7878";
    #     SONARR_PORT = "8989";
    #     HOME_ASS_IP = "http://10.0.50.10";
    #     HOME_ASS_PORT = "8123";
    #     NAS_IP = "http://10.0.50.2";
    #     PLEX_FALLBACK_PORT= "32401";
    #   };
    #   volumes = [ "${tigConfigDir}/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro" ];
    # };

  	# grafana = {
    #   image = "grafana/grafana:latest";
    #   ports = dockerPorts.grafana;
    #   user = "950";
    #   environment = {
    #   	PUID = "950";
    #   	PGID = "950";
    #   	GF_SECURITY_ADMIN_USER = "admin";
    #   	GF_SECURITY_ADMIN_PASSWORD = "admin";
    #   	GF_INSTALL_PLUGINS = "grafana-clock-panel";
    #   };
    #   volumes = [ "${tigConfigDir}/grafana/data:/var/lib/grafana" ];
    # };


    
  };
}
