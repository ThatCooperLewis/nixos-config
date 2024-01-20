{ config, pkgs, lib, ... }:

let

  tigConfigDir = "/home/cooper/tig-stack";

  ports = {
  	influxdb = 8086;
  	telegraf = 8125;
  	grafana = 3000;
  };

  dockerPorts = {
  	influxdb = ["${toString ports.influxdb}:${toString ports.influxdb}"];
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

    # Install docker, make it compatible with Nvidia GPUs
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

    influxdb = {
      image = "influxdb:1.8-alpine";
      ports = ["8086:8086"];
      environment = {
        # TODO Get a proper user for these
      	PUID = "1001";
      	PGID = "100";
      	INFLUX_DB = "influx";
      	INFLUXDB_ADMIN_USER = "admin";
      	INFLUXDB_ADMIN_PASSWORD = "admin";
      };
      volumes = "/home/cooper/tig-stack/influxdb/data:/var/lib/influxdb";
    };
  	
  };
}
