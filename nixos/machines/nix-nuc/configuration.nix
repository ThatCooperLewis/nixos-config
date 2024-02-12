{ config, pkgs, inputs, constants, ... }:

{
  ### Locale
  time.timeZone = constants.systemDefaults.timeZone;
  i18n.defaultLocale = constants.systemDefaults.defaultLocale;
  i18n.extraLocaleSettings = constants.systemDefaults.extraLocaleSettings;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable X11
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
  };
  # GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable automatic login
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "cooper";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  
  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  powerManagement.enable = false;
  
  # Audio settings
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.defaultUserShell = pkgs.zsh;
  users.users.cooper = {
    isNormalUser = true;
    description = "Cooper Lewis";
    extraGroups = [ "docker" "networkmanager" "wheel" "telegraf" ];
    packages = with pkgs; [
      firefox
    ];
  };

  # Define user/group for Plex Stack
  users.users.multimedia = {
    uid = 950;
    group = "multimedia";
  	description = "Plex Stack";
  	extraGroups = [ "docker" "networkmanager" "wheel" ];
  };
  users.groups.multimedia.gid = 950;

  users.users.cloudflare = {
    isSystemUser = true;
  	uid = constants.users.cloudflare;
  	group = "cloudflare";
  	description = "Cloudflared Tunnel";
  	extraGroups = [ "wheel" ]; 
  };
  users.users.uptime = {
    uid = constants.users.uptime;
    description = "Uptime Kuma";
    isNormalUser = false;
    group = "uptime";
    extraGroups = [ "wheel" ];
  };
  users.users.palworld = {
    uid = constants.users.palworld;
    description = "Palworld dedicated server";
    isSystemUser = true;
    group = "palworld";
    extraGroups = [ "wheel" ];
  };
  users.users.telegraf = {
    uid = 256;
    isSystemUser = true;
    group = "telegraf";
    extraGroups = [ "wheel" "docker" ];
  };
  users.groups.cloudflare.gid = constants.users.cloudflare;
  users.groups.uptime.gid = constants.users.uptime;
  users.groups.palworld.gid = constants.users.palworld;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    micro
    curl
    wget
    btop
    home-manager
    neofetch
    intel-gpu-tools
    vscode
    python3
    inputs.fix-python
    influxdb
  ];

  services.openssh.enable = true;

  services.telegraf.extraConfig = { 
    agent.hostname = "nix-nuc";
    inputs.http_response.urls = [ 
      constants.urls.plex
      constants.urls.tdarr
      constants.urls.overseerr
      constants.urls.sab
      constants.urls.radarr
      constants.urls.sonarr
      constants.urls.ha
      constants.urls.octopi
      constants.urls.uptime
    ];
  };

  programs.zsh.enable = true;

  system.stateVersion = "23.11";
}
