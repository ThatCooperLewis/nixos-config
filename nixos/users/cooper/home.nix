{ config, pkgs, ... }:

let 
  isARM = pkgs.system == "aarch64-linux";
in
{
  imports = [
  	./zsh.nix
  ];

  home.username = "cooper";
  home.homeDirectory = "/home/cooper";

  home.stateVersion = "23.11";

  home.file = {};

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  programs.git = {
  	enable = true;
  	userName = "Cooper Lewis";
  	userEmail = "thatcooperlewis@gmail.com";
  };

  #### VS Code
  # Only import VSCode if on an x86 system (extensions not supported on ARM)
  programs.vscode = if isARM then {} else {
    # https://nixos.wiki/wiki/Visual_Studio_Code
  	enable = true;
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
  	];
  	userSettings = {
  	  "files.autoSave" = "afterDelay";
      "git.confirmSync" = false;
      "git.autofetch" = true;
      "editor.accessibilitySupport" = "off";
      "remote.SSH.useLocalServer" = false;
  	  # These themes can't be installed here because they're not in the nixpkgs repo
      "update.mode" = "manual";
  	};
  };

  programs.zoxide = {
    # A better `cd`
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ]; 
  };
}
