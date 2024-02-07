{ config, lib, pkgs, inputs, constants, ... }:

{
  imports = [

    # Fancy audio fix for Star Citizen
    inputs.nix-gaming.nixosModules.pipewireLowLatency

  ];

  ### Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define linux kernel
  # Vanilla NixOS 23.11 had an older kernel that caused some Hyprland/Nvidia issues
  # Update 1/11/23: Downgraded from linuxPackages_latest because nvidia drivers wouldn't download
  # https://discourse.nixos.org/t/issues-with-my-nvidia-gpu-config/35327
  # https://search.nixos.org/packages?channel=23.11&from=0&size=50&sort=relevance&type=packages&query=linuxKernel.kernels
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Enable Flakes and the new command-line tool
  nix.settings = {
    # Enable flakes and new CLI
    experimental-features = [ "nix-command" "flakes" ];
    # Cache for nix-gaming
    # https://github.com/fufexan/nix-gaming
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
  ### Networking
  networking.networkmanager.enable = true;
  networking.hostName = "lewis-linux";
  networking.extraHosts = "127.0.0.1 modules-cdn.eac-prod.on.epicgames.com"; # Anticheat Fix
 


  ### Locale
  time.timeZone = constants.systemDefaults.timeZone;
  i18n.defaultLocale = constants.systemDefaults.defaultLocale;
  i18n.extraLocaleSettings = constants.systemDefaults.extraLocaleSettings;


  ### Display Configuration

  # The following is a nice backup if Hyprland shits the bed
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
  services.xserver.enable = true; # Might need this for Xwayland (Enable the X11 windowing system).
  programs.hyprland.enable = true;
  environment.sessionVariables = {
    # Fixes invisible mouse
    # This gave me many issues with Hyprland immediately crashing (but running again if I called `Hyprland`)
    # A mix of other settings here + in home.nix ended up resolving it
    # I think the main culprit was an outdate linux kernel (see above) plus adding the DRM_DEVICES flag below
    WLR_NO_HARDWARE_CURSORS = "1";
    
    # Define which GPU to use 
    # TODO: Split this into separate boot option
    WLR_DRM_DEVICES = "/dev/dri/card0";
    # WLR_DRM_DEVICES = "/dev/dri/card1"; If you're using second GPU and it's not detached from the host
    
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
      extraGroups = [ "networkmanager" "input" "wheel" "docker" "libvirtd" ];
    };
  };


  ### Packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ]; # Obsidian uses EOL electron :( 
  environment.systemPackages = with pkgs; [

	  # Hardware
    networkmanagerapplet 	# Internet GUI
    pavucontrol 			    # Pulseaudio GUI
    pipewire
    playerctl
    usbutils
    pciutils
    nvtop

    # Dev Tools
    git
    micro
    vscode
    wget
    curl
    (python3.withPackages(ps: with ps; [
      pyserial # Detect devices with serial ports (octoprint)
    ]))

    # Essentials
    btop
    home-manager
    kitty
    openssh
    zsh
    zplug         # Zsh plugin manager
    neofetch      # Display system info

    # Display & Graphics
    dunst				  # Notifications
    libnotify
    grim 				  # Screenshots
    rofi-wayland 	# App Switcher
    swww 			  	# Wallpaper
    waybar 				# Toolbar
    swtpm 			  # Virtual TPM
        
    # Media
    discord
    firefox
    spotify
    tidal-hifi
    obsidian
    
    # Gaming
    steam
    inputs.nix-gaming.packages.${system}.star-citizen 
  ];

  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      });
    })
  ];

  ### Fonts
  fonts.packages = with pkgs; [
    meslo-lgs-nf
    nerdfonts
  ];



  ### File Browsing
  programs.thunar.enable = true;
  services.gvfs.enable = true; # Mount, trash, other stuff
  services.tumbler.enable = true; # Thumbnail images
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

  # Set the default editor.
  environment.variables.EDITOR = "micro";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?  
}
