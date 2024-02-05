{
  containerDirs = {
    arr = "/home/cooper/Homelab/plex-stack";
    tig = "/home/cooper/tig-stack";
    kuma = "/home/cooper/tig-stack";
    plexData = "/mnt/plex-content";
    plexDataFallback = "/mnt/plex-content-fallback"; 
    plexData4k = "/mnt/plex-content-4k";
    usenetDownloads = "/mnt/plex-downloads/data/usenet";
    usenet4kDownloads = "/mnt/plex-downloads/data-4k/usenet";
    tdarrTranscode = "/mnt/nas-containers/tdarr/temp";
    palworld = "/home/cooper/Homelab/palworld";
  };

  ports = {
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
  	tautulli = 8181;
    
    
  	telegraf = 8125;
    influxdb = 8086;
  	grafana = 3000;
  	uptimeKuma = 3001;
    
    palworld = 8211;
    palworldSecondary = 27015;
  };

  dockerPorts = {
    octoprint = ["${toString ports.octoprint}:${toString ports.octoprint}"];
  	bazarr = ["${toString ports.bazarr}:${toString ports.bazarr}"];
    overseerr = ["${toString ports.overseerr}:${toString ports.overseerr}"];
    prowlarr = ["${toString ports.prowlarr}:${toString ports.prowlarr}"];
    radarr = ["${toString ports.radarr}:${toString ports.radarr}"];
    radarr4k = ["${toString ports.radarr4k}:${toString ports.radarr}"];
    requestrr = ["${toString ports.requestrr}:${toString ports.requestrr}"];
    sonarr = ["${toString ports.sonarr}:${toString ports.sonarr}"];
    sonarr4k = ["${toString ports.sonarr4k}:${toString ports.sonarr}"];
    tautulli = ["${toString ports.tautulli}:${toString ports.tautulli}"];
    tdarr = [ 
      "${toString ports.tdarrWeb}:${toString ports.tdarrWeb}" 
      "${toString ports.tdarrServer}:${toString ports.tdarrServer}" 
    ];

  	telegraf = ["${toString ports.telegraf}:${toString ports.telegraf}"];
    influxdb = ["${toString ports.influxdb}:${toString ports.influxdb}"];
  	grafana = ["${toString ports.grafana}:${toString ports.grafana}"];
  	uptimeKuma = ["${toString ports.uptimeKuma}:${toString ports.uptimeKuma}"];


    palworld = [
      "${toString ports.palworld}:${toString ports.palworld}/udp"
      "${toString ports.palworld}:${toString ports.palworld}/tcp"
      "${toString ports.palworldSecondary}:${toString ports.palworldSecondary}/udp"
      "${toString ports.palworldSecondary}:${toString ports.palworldSecondary}/tcp"
    ];
  };

  dockerDefaults = {
    environment = {
      TZ = "America/Los_Angeles";
      UMASK_SET = "022";
      PUID = "950";
      PGID = "950";
    };
    plexStackOptions = [ "--network=plex-stack" ];
  };
}