{ lib, constants, ...}:

let
  imports = [
    ./container-base.nix
  ];

  docker = constants.docker;
  allPorts = [
    8088
    8043
    19810
    27001
    29810
    29811
    29812
    29813
    29814
    29815
    29816
  ];
in {
  networking.firewall.allowedTCPPorts = allPorts;
  networking.firewall.allowedUDPPorts = allPorts;

  users.users.omada = {
    uid = constants.users.omada;
    description = "Omada Controller";
    isSystemUser = true;
    group = "omada";
    extraGroups = ["wheel"];
  };
  users.groups.omada.gid = constants.users.omada;

  virtualisation.oci-containers.containers.omada = {
    image = "mbentley/omada-controller:5.15";
    ports = [
      "8088:8088"
      "8043:8043"
      "27001:27001"
      "19810:19810"
      "29810:29810"
      "29811:29811"
      "29812:29812"
      "29813:29813"
      "29814:29814"
      "29815:29815"
      "29816:29816"
    ];
    environment = {
      PUID = "508";
      PGID = "508";
      MANAGE_HTTP_PORT = "8088";
      MANAGE_HTTPS_PORT = "8043";
      PORTAL_HTTP_PORT = "8088";
      PORTAL_HTTPS_PORT = "8843";
      PORT_APP_DISCOVERY = "27001";
      PORT_ADOPT_V1 = "29812";
      PORT_UPGRADE_V1 = "29813";
      PORT_MANAGER_V1 = "29811";
      PORT_MANAGER_V2 = "29814";
      PORT_DISCOVERY = "29810";
      PORT_TRANSFER_V2 = "29815";
      PORT_RTTY = "29816";
      SHOW_SERVER_LOGS = "true";
      SHOW_MONGODB_LOGS = "false";
      TZ = "America/Los_Angeles";
    };
    volumes = [
      "/var/lib/omada/data:/opt/tplink/EAPController/data"
      "/var/lib/omada/logs:/opt/tplink/EAPController/logs"
    ];
    extraOptions = ["--network=host"];
  };
}