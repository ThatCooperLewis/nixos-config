{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cooper";
  home.homeDirectory = "/home/cooper";

  # You should not change this value, even if you update Home Manager. It determines backwards compatibility
  home.stateVersion = "23.11"; # DO NOT EDIT

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
  	GBM_BACKEND = "nvidia-drm";
    GDK_BACKEND = "wayland";
    GDK_SCALE = "2";
    GLFW_IM_MODULE = "ibus";
    LIBVA_DRIVER_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
    NIXPKGS_ALLOW_UNFREE = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    WLR_BACKEND = "vulkan";
    WLR_DRM_NO_ATOMIC = "1";
    # WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
    XCURSOR_SIZE = "48";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;


  #### VS Code
  nixpkgs.config.allowUnfree = true;
  programs.vscode = {
    # https://nixos.wiki/wiki/Visual_Studio_Code
  	enable = true;
  	extensions = with pkgs.vscode-extensions; [
  	  # Themes
  	  # azemoh.one-monokai
      
      # Languages
  	  ms-python.python
  	  # kevinrose.vsc-python-indent
  	  ms-azuretools.vscode-docker
      bbenoist.nix
  	  
      # Tools
  	  github.copilot
  	];
  	userSettings = {
  	  "files.autoSave" = "afterDelay";
      # "workbench.colorTheme": "One Monokai",
      "git.confirmSync" = false;
      "git.autofetch" = true;
      "editor.accessibilitySupport" = "off";
      "window.titleBarStyle" = "custom";
  	};
  };


  #### Git
  programs.git = {
    # https://nixos.wiki/wiki/git
    enable = true;
    userName = "Cooper Lewis";
    userEmail = "thatcooperlewis@gmail.com";
  };


  #### Zsh
  programs.zsh = {
    # https://nixos.wiki/wiki/zsh
    enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
      update-home = "home-manager init --switch";
    };
    history = {
    	size = 30000;
        path = "${config.xdg.dataHome}/zsh/history";
    };

    # Source the powerlevel10k config
    # https://discourse.nixos.org/t/zsh-zplug-powerlevel10k-zshrc-is-readonly/30333/3
    initExtra = ''
      [[ ! -f ${./p10k.zsh} ]] || source ${./p10k.zsh}
    '';

    # Plugin management
    zplug = {
      enable = true;
      plugins = [
        { name = "plugins/git"; tags = [from:oh-my-zsh];}
        { name = "nvbn/thefuck";}
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "zsh-users/zsh-history-substring-search"; tags = [ as:plugin ]; }
        { name = "zsh-users/zsh-syntax-highlighting";}
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
        ];
    };

    # Up/Down Arrow keys to 
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "$terminfo[kcuu1]" "^[[B" ];
      searchDownKey = [ "$terminfo[kcud1]" "^[[A" ];
    };
  };
}
