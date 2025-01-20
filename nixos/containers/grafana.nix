{ lib, constants, ...}:

let
  docker = constants.docker;
  dataDir = constants.docker.dirs.grafana;
in
{
  users = {
    users.grafana = {
      isSystemUser = true;
      uid = constants.users.grafana;
      group = "grafana";
      description = "Grafana Dashboards User";
      extraGroups = [ "wheel" ];
    };
    groups.grafana.gid = constants.users.grafana;
  };

  # Copy the Cloudflare credentials from NAS
  system.activationScripts.ensureGrafanaDataDir = lib.mkAfter ''
      mkdir -p ${dataDir}
      chown -R ${docker.users.grafana}:${docker.users.grafana} ${dataDir}
  '';

  networking.firewall.allowedTCPPorts = [ constants.ports.grafana ];
  virtualisation.oci-containers.containers = {
    grafana = {
      image = "grafana/grafana:latest";
      ports = docker.ports.grafana;
      user = docker.users.grafana;
      environment = {
      	GF_SECURITY_ADMIN_USER = "admin";
      	GF_SECURITY_ADMIN_PASSWORD = "admin";
      	GF_INSTALL_PLUGINS = "grafana-clock-panel";
      };
      volumes = [ "${dataDir}:/var/lib/grafana" ];
      extraOptions = ["--user=${docker.users.grafana}"];
    };
  };
}