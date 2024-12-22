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
    octopi = "http://10.0.50.12";
  };

  users = {
    cloudflare = 2002;
    influxdb = 125;
    grafana = 950;
    minecraft = 1776;
    multimedia = 950;
    navidrome = 950;
    octoprint = 333;
    palworld = 1400;
    tailscale = 1984;
    uptime = 900;
  };

  ports = {
    octoprint = 5000;

    plex = 32400;
    bazarr = 6767;
  	overseerr = 5055;
  	prowlarr = 9696;
  	lidarr = 8686;
  	radarr = 7878;
  	radarr4k = 7879;
  	requestrr = 4545;
  	sonarr = 8989;
  	sonarr4k = 8990;
  	tdarrServer = 8266; # 8265 for Web Portal, 8266 for Node/Server interop
  	tdarrWeb = 8265;
  	tautulli = 8181;
    sab = 30055;
    scrutiny = 31054;
    
    homeAss = 8123;

    tailscale = 41641;
  	telegraf = 8125;
    influxdb = 8086;
  	grafana = 3000;
  	uptime = 3001;
    
    navidrome = 4533;

    palworld = 8211;
    palworldSecondary = 27015;
    minecraft = 6900;
  };

  plexStackIP = hosts.nuc; 

  localTimeZone = "America/Los_Angeles";

in {

  # Expose local variables to the rest of the config
  inherit hosts users ports plexStackIP localTimeZone;

  systemDefaults = {
    timeZone = localTimeZone;
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

  nuc = {
    dirs = {
      plexStack = "/home/cooper/Homelab/plex-stack";
      plexStackBackup = "/mnt/primary-backup/plex-stack";
    };
  };

  urls = {
    # NUC Mini PC
    lidarr = "${plexStackIP}:${toString ports.lidarr}";
    sonarr = "${plexStackIP}:${toString ports.sonarr}";
    sonarr4k = "${plexStackIP}:${toString ports.sonarr4k}";
    radarr = "${plexStackIP}:${toString ports.radarr}";
    radarr4k = "${plexStackIP}:${toString ports.radarr4k}";
    prowlarr = "${plexStackIP}:${toString ports.prowlarr}";
    overseerr = "${plexStackIP}:${toString ports.overseerr}";
    requestrr = "${plexStackIP}:${toString ports.requestrr}";
    tdarr = "${plexStackIP}:${toString ports.tdarrWeb}";
    tautulli = "${plexStackIP}:${toString ports.tautulli}"; 
  	grafana = "${hosts.nuc}:${toString ports.grafana}";
    influxdb = "${hosts.nuc}:${toString ports.influxdb}";
    # TrueNAS Apps
  	nas = "${hosts.nas}";
  	plex = "${hosts.nas}:${toString ports.plex}";
  	sab = "${hosts.nas}:${toString ports.sab}";
    scrutiny = "${hosts.nas}:${toString ports.scrutiny}";
    # Monitor Pi
  	uptime = "${hosts.monitor}:${toString ports.uptime}";
    # Home Assistant
  	ha = "${hosts.homeAss}:${toString ports.homeAss}";
    # Wifi AP
  	wifi = "${hosts.wap}";
    # Octoprint RasPi
  	octopi = "${hosts.octopi}";   
  };

  docker = {
    tdarrServerIP = "10.0.50.4";
    plexArgs = [ "--network=plex-stack" ];
    environment = {
      TZ = localTimeZone;
      UMASK_SET = "022";
      PUID = "${toString users.multimedia}";
      PGID = "${toString users.multimedia}";
    };

    users = {
      multimedia = "${toString users.multimedia}";
      uptime = "${toString users.uptime}";
      grafana = "${toString users.grafana}";
      cloudflare = "${toString users.cloudflare}";
      palworld = "${toString users.palworld}";
      navidrome = "${toString users.navidrome}";
      octoprint = "${toString users.octoprint}";
    };
    
    ports = {
      octoprint = ["${toString ports.octoprint}:${toString ports.octoprint}"];
      bazarr = ["${toString ports.bazarr}:${toString ports.bazarr}"];
      overseerr = ["${toString ports.overseerr}:${toString ports.overseerr}"];
      prowlarr = ["${toString ports.prowlarr}:${toString ports.prowlarr}"];
      lidarr = ["${toString ports.lidarr}:${toString ports.lidarr}"];
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
      navidrome = ["${toString ports.navidrome}:${toString ports.navidrome}"];
      telegraf = ["${toString ports.telegraf}:${toString ports.telegraf}"];
      influxdb = ["${toString ports.influxdb}:${toString ports.influxdb}"];
      grafana = ["${toString ports.grafana}:${toString ports.grafana}"];
      uptime = ["${toString ports.uptime}:${toString ports.uptime}"];
      palworld = [
        "${toString ports.palworld}:${toString ports.palworld}/udp"
        "${toString ports.palworld}:${toString ports.palworld}/tcp"
        "${toString ports.palworldSecondary}:${toString ports.palworldSecondary}/udp"
        "${toString ports.palworldSecondary}:${toString ports.palworldSecondary}/tcp"
      ];
    };

    dirs = {
      arr = "/home/cooper/Homelab/plex-stack";
      telegraf = "/home/telegraf";
      grafana = "/home/cooper/Homelab/grafana";
      uptime = "/home/cooper/uptime-stack";
      navidrome = "/home/cooper/navidrome-stack";
      octoprint = "/home/cooper/octoprint";
      plexData = "/mnt/plex-content";
      plexData4k = "/mnt/plex-content-4k";
      usenetDownloads = "/mnt/plex-downloads/data/usenet";
      usenet4kDownloads = "/mnt/plex-downloads/data-4k/usenet";
      tdarrTranscode = "/mnt/nas-tdarr/temp";
      palworld = "/home/cooper/Homelab/palworld";
      minecraft = "/var/lib/minecraft";
    };
  };
}
