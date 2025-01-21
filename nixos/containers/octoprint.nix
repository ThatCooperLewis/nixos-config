{ config, constants, ... }:
/*

Octoprint, web UI for controlling 3D Printers
https://github.com/OctoPrint/octoprint-docker/blob/master/docker-compose.yml

*/

{
  imports = [
    ./container-base.nix
  ];

  config.networking.firewall.allowedTCPPorts = [ constants.ports.octoprint ];
  config.users.users.octoprint = {
    uid = constants.users.octoprint;
    description = "Octoprint";
    isSystemUser = true;
    group = "octoprint";
    extraGroups = [ "wheel" ];
  };
  config.users.groups.octoprint.gid = constants.users.octoprint;

  config.virtualisation.oci-containers.containers = {
    octoprint = {
      image = "octoprint/octoprint:latest";
      ports = [ "${toString constants.ports.octoprint}:${toString constants.ports.octoprint}" ];
      # devices = [ "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0:/dev/ttyUSB0" ];
      environment = {
      	PUID = constants.docker.users.octoprint;
      	PGID = constants.docker.users.octoprint;
      };
      volumes = ["${constants.docker.dirs.octoprint}:/octoprint"];
      environment = {
        OCTOPRINT_ENV = "production";
      };
      # hostConfig = {
      #   privileged = true; # Allows privileged access to the container
      #   devices = [ 
      #     { hostPath = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0"; containerPath = "/dev/ttyUSB0"; }
      #   ];
      # };
      extraOptions = ["--device=/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0:/dev/ttyUSB0" "--privileged"];
    };
  };
}
