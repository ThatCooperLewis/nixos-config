let

  ips = {
    brain = "10.0.50.1";
    nas = "10.0.50.2";
    photonas = "10.0.50.3";
    nuc = "10.0.50.4";
    nuc-old = "10.0.50.6";

    homeAss = "10.0.50.10";

    caddyPi = "10.0.50.30";
    fallbackPi = "10.0.50.31";
    fortressPi = "10.0.50.33";
    octoprint = "10.0.50.34";
    adguard = "10.0.100.0";
  };

  hosts = {
    firewall = "https://10.0.30.30";
    wap = "http://10.0.50.0";

    brain = "http://10.0.50.1";	
    nas = "http://10.0.50.2";
    photonas = "http://10.0.50.3";
    nuc = "http://10.0.50.4";
    nuc-old = "http://10.0.50.6";
    
    # Rasp Pi's
    monitor = "http://10.0.50.3";
    homeAss = "http://10.0.50.10";
    octoprint = "http://10.0.50.34";
    caddypi = "http://10.0.50.30";
    adguard = "http://10.0.100.0";
  };

  tails = {
    brain = "http://100.101.81.63";
    nas = "http://100.86.97.79";
    nuc = "http://100.80.253.64";
    nuc-old = "http://100.81.70.111";
    windows = "http://100.88.50.101";
    caddypi = "http://100.69.31.128";
    homeAss = "http://100.102.14.66";
    adguard = "http://100.124.121.82";
    remote = "http://100.68.249.124";
  };

  users = {
    caddypi = 2222;
    cloudflare = 2002;
    influxdb = 992;
    grafana = 472;
    minecraft = 1776;
    multimedia = 950;
    navidrome = 950;
    octoprint = 333;
    omada = 508;
    palworld = 1400;
    tailscale = 1984;
    uptime = 900;
  };

  ports = {
    adguard = 3003;
    bazarr = 6767;
    caddypi = 80;
    caddypiSSH = 443;
    geocitiesPortfolio = 8080;
    dns = 53;
  	grafana = 3000;
    homeAss = 8123;
    influxdb = 8086;
  	lidarr = 8686;
    minecraft = 19132;
    navidrome = 4533;
    octoprint = 5000;
    omada = 8043;
  	overseerr = 5055;
    palworld = 8211;
    palworldSecondary = 27015;
    plex = 32400;
  	prowlarr = 9696;
  	radarr = 7878;
  	radarr4k = 7879;
  	requestrr = 4545;
    sab = 30055;
    scrutiny = 31054;
  	sonarr = 8989;
  	sonarr4k = 8990;
    tailscale = 41641;
  	tautulli = 8181;
  	telegraf = 8125;
  	tdarrServer = 8266; # 8266 for Node/Server interop
  	tdarrWeb = 8265; # 8265 for Web Portal
  	uptime = 3001;
    xrdp = 3389;
  };

  plexStackIP = hosts.nuc; 

  localTimeZone = "America/Los_Angeles";

in {

  # Expose local variables to the rest of the config
  inherit ips hosts users ports plexStackIP localTimeZone tails;

  sshKeys = [
    # ssh-keygen -t ed25519 -C "hostname"

    # cooper@macbook
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/veCx5UoXbcJagSUN0/dL8xBA6FxxeLn/h8i9xQLoJ cooper-mbp"
    
    # cooper@nix-brain
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkiU50BcIBPk6MsbUNw8Rmol/cApjRrVjRvAt/IlJqG nix-brain"
    # root@nix-brain
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuFaNqrc/rm3EHHa1ah0I/S+wxXEC9vnmkse/kfNG0H nix-brain"
    
    # cooper@nix-nuc
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJk/2Xmwc8tbST0xXD7uMCnEK3ys9Mgr+SfRXZMYwh2y nix-nuc"
    # root@nix-nuc
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMr71CE+bzLkDKdvL7iBU/gETtgMNOK449EQl9JcDokd nix-nuc-root"
  ];

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
      geocitiesPortfolio = "/var/www/geocities-portfolio";
    };
  };

  nfs = {
    dirs = {
      secrets = {
        deviceSource = "${ips.nas}:/mnt/janet/secrets";
        mountPath = "/mnt/nas-secrets";
      };
      plex = {
        deviceSource = "${ips.nas}:/mnt/apps/plex";
        mountPath = "/mnt/nas-plex";
      };
      backup = {
        deviceSource = "${ips.nas}:/mnt/janet/backup-data/homelab";
        mountPath = "/mnt/nas-backup";
      };
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
    influxdb = "${hosts.brain}:${toString ports.influxdb}";
    # TrueNAS Apps
  	nas = "${hosts.nas}";
  	photonas = "${hosts.photonas}";
  	plex = "${hosts.nas}:${toString ports.plex}";
  	sab = "${hosts.nas}:${toString ports.sab}";
    scrutiny = "${hosts.nas}:${toString ports.scrutiny}";
    # Monitor Pi
  	uptime = "${hosts.monitor}:${toString ports.uptime}";
    # Home Assistant
  	homeAss = "${hosts.homeAss}:${toString ports.homeAss}";
    # Wifi AP
  	wifi = "${hosts.wap}";
    # Octoprint RasPi
  	octoprint = "${hosts.octoprint}";
    # Caddy-Cloudflare RasPi   
    caddypi = "${hosts.caddypi}";
  };

  services = {
    dirs = {
      plexMirror = "/mnt/local-raid/plex";
      influxdb = "/mnt/local-raid/influxdb";
    };
  };

  docker = {
    tdarrServerIP = "10.0.50.4";
    plexArgs = [ "--network=plex-stack" "--pull=always" ];
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
      caddypi = "${toString users.caddypi}";
      cloudflare = "${toString users.cloudflare}";
      palworld = "${toString users.palworld}";
      navidrome = "${toString users.navidrome}";
      octoprint = "${toString users.octoprint}";
      minecraft = "${toString users.minecraft}";
    };
    
    ports = {
      caddypi = [ 
        "${toString ports.caddypi}:${toString ports.caddypi}" 
        "${toString ports.caddypiSSH}:${toString ports.caddypiSSH}" 
        "${toString ports.caddypiSSH}:${toString ports.caddypiSSH}/udp" 
      ];
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
      minecraft = ["${toString ports.minecraft}:${toString ports.minecraft}/udp"];
    };

    dirs = {
      arr = "/home/cooper/Homelab/plex-stack";
      telegraf = "/home/telegraf";
      grafana = "/var/lib/grafana";
      uptime = "/home/cooper/uptime-stack";
      navidrome = "/home/cooper/navidrome-stack";
      octoprint = "/home/cooper/octoprint";
      plexData = "/mnt/plex-content";
      plexDataUnified = "/mnt/plex-content-unified";
      palworld = "/home/cooper/Homelab/palworld";
      minecraft = "/var/lib/minecraft";
      caddypi = "/etc/caddy";
    };
  };
}
