{ config, constants, ...}:

let
  docker = constants.docker;
in
{
  config.networking.firewall.allowedTCPPorts = [ constants.ports.grafana ];
  config.virtualisation.oci-containers.containers = {
    grafana = {
      image = "grafana/grafana:latest";
      ports = docker.ports.grafana;
      user = docker.users.grafana;
      environment = {
      	PUID = docker.users.grafana;
      	PGID = docker.users.grafana;
      	GF_SECURITY_ADMIN_USER = "admin";
      	GF_SECURITY_ADMIN_PASSWORD = "admin";
      	GF_INSTALL_PLUGINS = "grafana-clock-panel";
      };
      volumes = [ "${docker.dirs.grafana}/data:/var/lib/grafana" ];
    };
  };
}