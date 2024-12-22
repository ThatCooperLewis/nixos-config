{ pkgs, app, user, constants, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  services.caddy = {
  	enable = true;
    virtualHosts = {

      # NUC Mini PC
      "http://sonarr.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.sonarr}
      '';
      "http://sonarr4k.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.sonarr4k}
      '';
      "http://radarr.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.radarr}
      '';
      "http://radarr4k.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.radarr4k}
      '';
      "http://prowlarr.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.prowlarr}
      '';
      "http://overseerr.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.overseerr}
      '';
      "http://requestrr.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.requestrr}
      '';
      "http://tdarr.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.tdarr}
      '';
      "http://tautulli.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.tautulli}
      '';    
      
      # TrueNAS Apps
      "http://nas.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.nas}
      '';
      "http://plex.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.plex}
      '';
      "http://sab.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.sab}
      '';
      "http://scrutiny.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.scrutiny}
      '';

      # Monitor Pi
      "http://uptime.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.uptime}
      '';
      "http://grafana.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.grafana}
      '';

      # Home Assistant
      "http://ha.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.ha}
      '';

      # Wifi AP
      "http://wifi.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.wifi}
      '';

      # Octoprint RasPi
      "http://octopi.lewis.arpa".extraConfig = ''
        reverse_proxy ${constants.urls.octopi}
      '';        
    };
  };
}
