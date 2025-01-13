{ config, pkgs, lib, ... }:

let

  hostIP = "10.0.50.1";


  ports = {
    octoprint = 5000;
  };

  dockerPorts = {
    octoprint = ["${toString ports.octoprint}:${toString ports.octoprint}"];
 };

 defaultEnvironment = {
    TZ = "America/Los_Angeles";
    UMASK_SET = "022";
    PUID = "950";
    PGID = "950";
 };
  
in {

  # Configure firewall to allow containers access to each other and external internet
  config.networking.firewall = {
    enable = true;
    # Containers don't get their ports exposed by default
    allowedTCPPorts = lib.attrValues ports;
    allowedUDPPorts = [];
    interfaces.docker1 = {
      # Allow ports to query each other
      allowedUDPPorts = [ 53 ];
    };
  };

  # Install docker, make it compatible with Nvidia GPUs
  config.virtualisation.docker = {
  	enable = true;
  	enableNvidia = true;
  	enableOnBoot = true;
  };

  # libnvidia-container does not support cgroups v2 (prior to 1.8.0)
  # https://github.com/NVIDIA/nvidia-docker/issues/1447
  # config.systemd.enableUnifiedCgroupHierarchy = false;

  # OCI Backend is Podman by default
  # It does not support Nvidia GPUs with Plex 
  config.virtualisation.oci-containers.backend = "docker";

  config.virtualisation.oci-containers.containers = {

  };
}
