{ pkgs, app, user, constants, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  services.caddy = {
  	enable = true;

  	# NUC Mini PC
  	virtualHosts."http://sonarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.sonarr}
  	'';
  	virtualHosts."http://sonarr4k.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.sonarr4k}
  	'';
  	virtualHosts."http://radarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.radarr}
    '';
  	virtualHosts."http://radarr4k.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.radarr4k}
    '';
  	virtualHosts."http://prowlarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.prowlarr}
    '';
  	virtualHosts."http://overseerr.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.overseerr}
    '';
  	virtualHosts."http://requestrr.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.requestrr}
    '';
  	virtualHosts."http://tdarr.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.tdarr}
    '';
  	virtualHosts."http://tautulli.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.tautulli}
    '';    

    # TrueNAS Apps
  	virtualHosts."http://nas.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.nas}
    '';
  	virtualHosts."http://plex.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.plex}
    '';
  	virtualHosts."http://sab.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.sab}
    '';
    virtualHosts."http://scrutiny.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.scrutiny}
    '';

    # Monitor Pi
  	virtualHosts."http://uptime.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.uptime}
    '';
  	virtualHosts."http://grafana.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.grafana}
    '';

    # Home Assistant
  	virtualHosts."http://ha.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.ha}
    '';

    # Wifi AP
  	virtualHosts."http://wifi.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.wifi}
    '';

    # Octoprint RasPi
  	virtualHosts."http://octopi.lewis.arpa".extraConfig = ''
      reverse_proxy ${constants.urls.octopi}
    '';        
  };
}
