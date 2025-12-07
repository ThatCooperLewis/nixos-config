# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, constants, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      
      # Fancy audio fix for Star Citizen
      inputs.nix-gaming.nixosModules.pipewireLowLatency
      # SteamOS optimizations
      inputs.nix-gaming.nixosModules.platformOptimizations
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  
  # Star Citizen optimizations
  # https://wiki.starcitizen-lug.org/Alternative-Installations#nixos-installation
  boot.kernel.sysctl = {
    # "vm.max_map_count" = 16777216; # Covered by nix-gaming.nixosModules.platformOptimizations
    "fs.file-max" = 524288;
  };
  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "nix-game";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  chaotic.hdr.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    lowLatency.enable = true;
  
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cooper.packages = with pkgs; [
    kdePackages.kate
  ];

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    
    # Terminal
    btop
    cowsay
    curl
    fastfetch
    fish
    kitty
    micro
    wget

    # Development
    code-cursor
    git
    python3
    vscode
    ngrok

    # Media
    discord
    tidal-hifi
    obsidian

    # Gaming
    wine
    gamescope
    lutris
    vulkan-tools
    vulkan-validation-layers
    vulkan-loader
    inputs.nix-citizen.packages.${stdenv.hostPlatform.system}.star-citizen
    inputs.nix-citizen.packages.${stdenv.hostPlatform.system}.lug-helper # Not necessary for installing game, but has nice tools
  ];

  environment.variables = {
    OLLAMA_ORIGINS = "*";
  };

  services.ollama = {
    enable = true;
    environmentVariables = {};
    port = 11434;
  };
  
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    # nix-gaming module, enables SteamOS sysctl optimizations
    # https://github.com/fufexan/nix-gaming?tab=readme-ov-file#platform-optimizations
    platformOptimizations.enable = true;
  };


  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
