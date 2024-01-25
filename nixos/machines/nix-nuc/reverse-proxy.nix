{ pkgs, app, user, ... }:
let
  # Device IPs
  

  hosts = {
    firewall = "https://10.0.30.30";

    wap = "http://10.0.50.0";
    primary = "http://10.0.50.1";	
    nas = "http://10.0.50.2";
    monitor = "http://10.0.50.3";
    nuc = "http://10.0.50.4";

    homeAss = "http://10.0.50.10";
    octopi = "http://10.0.50.11";
  };

  ports = {
    plex = 32400;
    octoprint = 5000;
    bazarr = 6767;
    overseerr = 5055;
    prowlarr = 9696;
    radarr = 7878;
    radarr4k = 7879;
    requestrr = 4545;
    sonarr = 8989;
    sonarr4k = 8990;
    tdarrServer = 8266; # 8265 for Web Portal, 8266 for Node/Server interop
    tdarrWeb = 8265;
    sab = 30055;
    palworld = 8211;
    palworldSecondary = 27015;
    scrutiny = 10151;
    grafana = 3000;
    influxdb = 8086;
    uptimeKuma = 3001;
    homeAss = 8123;
  };

  # Convenience assignments
  plexStackIP = hosts.nuc; 
  
in {
  services.caddy = {
  	enable = true;

  	# NUC Mini PC
  	virtualHosts."sonarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.sonarr}
      tls internal
  	'';
  	virtualHosts."sonarr4k.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.sonarr4k}
      tls internal
  	'';
  	virtualHosts."radarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.radarr}
      tls internal
    '';
  	virtualHosts."radarr4k.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.radarr4k}
      tls internal
    '';
  	virtualHosts."prowlarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.prowlarr}
      tls internal
    '';
  	virtualHosts."overseerr.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.overseerr}
      tls internal
    '';
  	virtualHosts."requestrr.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.requestrr}
      tls internal
    '';
  	virtualHosts."tdarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${plexStackIP}:${toString ports.tdarrWeb}
      tls internal
    '';

    # TrueNAS Apps
  	virtualHosts."nas.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.nas}
    '';
  	virtualHosts."plex.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.nas}:${toString ports.plex}
      tls internal
    '';
  	virtualHosts."sab.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.nas}:${toString ports.sab}
      tls internal
    '';
    virtualHosts."scrutiny.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.nas}:${toString ports.scrutiny}
      tls internal
    '';

    # Monitor Pi
  	virtualHosts."uptime.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.monitor}:${toString ports.uptimeKuma}
      tls internal
    '';
  	virtualHosts."grafana.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.monitor}:${toString ports.grafana}
      tls internal
    '';

    # Home Assistant
  	virtualHosts."ha.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.homeAss}:${toString ports.homeAss}
      tls internal
    '';

    # Wifi AP
  	virtualHosts."http://wifi.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.wap}
    '';

    # Octoprint RasPi
  	virtualHosts."octopi.lewis.arpa".extraConfig = ''
      reverse_proxy ${hosts.octopi}
      tls internal
    '';        
  };
}
