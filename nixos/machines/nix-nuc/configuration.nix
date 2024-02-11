{ config, pkgs, inputs, constants ... }:

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

  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  
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
  	uid = 2002;
  	group = "cloudflare";
  	description = "Cloudflared Tunnel";
  	extraGroups = [ "wheel" ]; 
  };
  users.users.uptime = {
    uid = 900;
    description = "Uptime Kuma";
    isNormalUser = false;
    group = "uptime";
    extraGroups = [ "wheel" ];
  };
  users.users.palworld = {
    uid = 1400;
    description = "Palworld dedicated server";
    isSystemUser = true;
    group = "palworld";
    extraGroups = [ "wheel" ];
  };
  users.users.telegraf = {
    uid = 1200;
    description = "Telegraf metrics emitter";
    isNormalUser = true;
    group = "telegraf";
    extraGroups = [ "wheel" ];
  };
  users.groups.cloudflare.gid = 2002;
  users.groups.uptime.gid = 900;
  users.groups.palworld.gid = 1400;
  users.groups.telegraf.gid = 1200;

  # Enable automatic login
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "cooper";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

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
  ];

  services.openssh.enable = true;

  programs.zsh.enable = true;

  system.stateVersion = "23.11";
}
