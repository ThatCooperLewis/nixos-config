{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # All docker containers
      ./containers.nix

      # Home Manager
      # https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module
      # See unpure-commands.md for initial setup
      <home-manager/nixos>
    ];



  ### Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define linux kernel
  # Vanilla NixOS 23.11 had an older kernel that caused some Hyprland/Nvidia issues
  boot.kernelPackages = pkgs.linuxPackages_latest;

  
  
  ### Networking
  networking.networkmanager.enable = true;
  networking.hostName = "lewis-linux";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
 


  ### Locale
  time.timeZone = "America/Los_Angeles";
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


  ### Display Configuration

  # The following is a nice backup if Hyprland shits the bed
  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };
  # Enable interop between app UI + screensharing
  xdg.portal.enable = true;
  # Not necessary to include hytland portal if hyprland.nvidiaSettings is on
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];



  ### Nvidia, oh Nvidia
  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];
  # Add nvidia to kernel module manually
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  # Other configs
  hardware.nvidia = {
    # Define driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # Modesetting is required.
    modesetting.enable = true;
    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;
    # Use the NVidia open source kernel module
    # Known to be buggy
    open = true;
    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;
  };


  ### Hyprland
  services.xserver.displayManager.sddm.enable = true; #This line enables sddm
  services.xserver.enable = true; # Might need this for Xwayland  
  programs.hyprland.enable = true;
  environment.sessionVariables = {
    # Fixes invisible mouse
    # This gave me many issues with Hyprland immediately crashing (but running again if I called `Hyprland`)
    # A mix of other settings here + in home.nix ended up resolving it
    # I think the main culprit was an outdate linux kernel (see above) plus adding the DRM_DEVICES flag below
    WLR_NO_HARDWARE_CURSORS = "1";
    # Define which GPU to use (3080)
    WLR_DRM_DEVICES = "/dev/dri/card0";
    # Tells electron apps to use Wayland
    NIXOS_OZONE_WL = "1";
  };
  

  
  ### Audio
  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };



  ### Users
  users = {
  	defaultUserShell = pkgs.zsh;
  	users.cooper = {
  	  useDefaultShell = true;
      isNormalUser = true;
      description = "Cooper Lewis";
      extraGroups = [ "networkmanager" "input" "wheel" "docker" ];
    };
  };



  ### Home Manager
  # Install packages to /etc/profile instead of ~/.nix-profile – Per the docs, this may become the default in the future
  home-manager.useUserPackages = true;
  # Import everything else directly from file
  home-manager.users.cooper = import /home/cooper/.config/home-manager/home.nix;



  ### Packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ]; # Obsidian uses EOL electron :( 
  environment.systemPackages = with pkgs; [

    # Dev Tools
    btop
    git
    kitty
    micro
    openssh
    vscode
    wget
    zplug
    zsh

    # Homelab
    home-manager

    # Display & Graphics
    dunst				  # Notifications
    libnotify
    grim 				  # Screenshots
    networkmanagerapplet
    rofi-wayland 	# App Switcher
    swww 			  	# Wallpaper
    waybar 				# Toolbar
    (waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      })
    )
    
    # Media
    discord
    firefox
    spotify
    steam
    tidal-hifi
    obsidian
  ];


  ### Fonts
  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];



  ### File Browsing
  # programs.thunar.enable = true;
  # services.gvfs.enable = true; # Mount, trash, other stuff
  # services.tumbler.enable = true; # Thumbnail images
  # TODO: Configure thunar more (details in wiki)



  ### Make server reachable via SSH
  services.openssh = {
  	enable = true;
  	settings = {
  	  PasswordAuthentication = true;
  	};
  };



  ### Miscellaneous
  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # If setting default user shell to zsh, this is necessary
  programs.zsh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?  
}
