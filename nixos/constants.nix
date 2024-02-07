let

  hosts = {
    firewall = "https://10.0.30.30";
    wap = "http://10.0.50.0";

    primary = "http://10.0.50.1";	
    nas = "http://10.0.50.2";
    nuc = "http://10.0.50.4";
    
    # Rasp Pi's
    monitor = "http://10.0.50.3";
    homeAss = "http://10.0.50.10";
    octopi = "http://10.0.50.11";
  };

  ports = {
    octoprint = 5000;

    plex = 32400;
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
    sab = 30055;
    scrutiny = 10151;
    
    homeAss = 8123;

  	telegraf = 8125;
    influxdb = 8086;
  	grafana = 3000;
  	uptimeKuma = 3001;
    
    palworld = 8211;
    palworldSecondary = 27015;
  };

  plexStackIP = hosts.nuc; 

in {

  # Expose local variables to the rest of the config
  inherit hosts ports plexStackIP;

  systemDefaults = {
    timeZone = "America/Los_Angeles";
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  
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

  urls = {
    # NUC Mini PC
    sonarr = "${plexStackIP}:${toString ports.sonarr}";
    sonarr4k = "${plexStackIP}:${toString ports.sonarr4k}";
    radarr = "${plexStackIP}:${toString ports.radarr}";
    radarr4k = "${plexStackIP}:${toString ports.radarr4k}";
    prowlarr = "${plexStackIP}:${toString ports.prowlarr}";
    overseerr = "${plexStackIP}:${toString ports.overseerr}";
    requestrr = "${plexStackIP}:${toString ports.requestrr}";
    tdarr = "${plexStackIP}:${toString ports.tdarrWeb}";
    tautulli = "${plexStackIP}:${toString ports.tautulli}"; 
    # TrueNAS Apps
  	nas = "${hosts.nas}";
  	plex = "${hosts.nas}:${toString ports.plex}";
  	sab = "${hosts.nas}:${toString ports.sab}";
    scrutiny = "${hosts.nas}:${toString ports.scrutiny}";
    # Monitor Pi
  	uptime = "${hosts.monitor}:${toString ports.uptimeKuma}";
  	grafana = "${hosts.monitor}:${toString ports.grafana}";
    # Home Assistant
  	ha = "${hosts.homeAss}:${toString ports.homeAss}";
    # Wifi AP
  	wifi = "${hosts.wap}";
    # Octoprint RasPi
  	octopi = "${hosts.octopi}";   
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