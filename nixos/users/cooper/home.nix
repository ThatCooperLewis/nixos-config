{ config, pkgs, lib, ... }:

let 
  isMacOS = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
  supportsCode = pkgs.stdenv.hostPlatform.system != "aarch64-linux"; # VS Code Extensions are not supported on raspberry pi
  synthwaveTheme = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "robbowen";
      name      = "synthwave-vscode";
      version   = "0.1.17";
      sha256 = "sha256-kSBYSrS/6ySMO9WWpIRRtWgX1gZV1S8QGPOOBJ59AKo=";
    };
  };
in
{
  imports = [
  	./fish.nix
  ];

  # Stop warning of overwriting fish config
  xdg.configFile."fish/config.fish".force = true;

  programs.home-manager.enable = true;

  home = if isMacOS then {
    username = "cooper";    # TODO: Pass this in as an arg from the flake-level
    stateVersion = "24.11"; # TODO: Pass this in as an arg from the flake-level
    packages = with pkgs; [
      eza
      bat
      ripgrep
      fzf
    ];
  } else {
    username = "cooper";
    stateVersion = "23.11"; # TODO: Pass this in as an arg from the flake-level
    homeDirectory = "/home/cooper";
    packages = with pkgs; [
      eza
      bat
      ripgrep
      fzf
    ];
  };

  # Provide custom files to the home directory
  # home.file = {};

  programs.git = {
  	enable = true;
    settings = {
      fetch.prune = true;
      user = {
        name = "Cooper Lewis";
        email = "thatcooperlewis@gmail.com";
      };
    };
  };

  #### VS Code
  programs.vscode = lib.mkIf supportsCode {
    # https://nixos.wiki/wiki/Visual_Studio_Code
  	enable = true;
  	profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Languages
        ms-python.python
        # kevinrose.vsc-python-indent
        ms-azuretools.vscode-docker
        bbenoist.nix
        dotjoshjohnson.xml

        # Tools
        github.copilot      
        eamodio.gitlens
        ms-vscode-remote.remote-ssh

        # Themes
        file-icons.file-icons # TODO: Convert this to custom extension declaration
        synthwaveTheme
      ];
      userSettings = {
        "files.autoSave" = "afterDelay";
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "editor.accessibilitySupport" = "off";
        "remote.SSH.useLocalServer" = false;
        "update.mode" = "manual";

        "workbench.colorTheme" = "SynthWave '84";
        "workbench.iconTheme" = "file-icons";
        "editor.fontFamily" = "FiraMono Nerd Font Mono";
        "editor.minimap.enabled" = false;
        "terminal.integrated.commandsToSkipShell" = [ "-workbench.action.quickOpenView" ];
        "explorer.confirmDelete" = false;
        "diffEditor.ignoreTrimWhitespace" = false;
        "explorer.confirmDragAndDrop" = false;
        "editor.tabSize" = 2;
        "synthwave84.disableGlow" = true;
        "synthwave84.brightness" = 0;
        "remote.SSH.remotePlatform" = {
          "nix-nuc" = "linux";
          "nix-nas" = "linux";
          "10.0.50.4" = "linux";
        };
        "terminal.integrated.profiles.linux"= {
          "fish"= {
            "path"= "/run/current-system/sw/bin/fish";
          };
        };
        "terminal.integrated.defaultProfile.linux"= "fish";
      };
    };
  };

  programs.zoxide = {
    # A better `cd`
    enable = true;
    # enableZshIntegration = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ]; 
  };

  programs.eza = { 
    # A better `ls`
    # https://github.com/ogham/exa (deprecated in favor of `eza`)
    # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.eza.enable
    enable = true;
    # enableZshIntegration = true;
    enableFishIntegration = true;
    icons = "auto";
    colors = "auto";
  };
}
