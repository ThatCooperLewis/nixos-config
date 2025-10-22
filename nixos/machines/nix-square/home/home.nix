{ config, pkgs, ... }:

{

  imports =
    [
      ./zsh.nix
    ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cooperl";
  # home.homeDirectory = "/Users/cooperl";

  # You should not change this value, even if you update Home Manager. It determines backwards compatibility
  home.stateVersion = "23.11"; # DO NOT EDIT

  home.sessionVariables = {
    DEVELOPMENT_TEAM_ID="UA9S8MKZ5F";
    PRE_COMMIT_HOOK_AUTO_RESOLVE_ERRORS_AND_COMMIT = "1";
    # These lived on my old work machine. Probably don't need them, but keeping them around anyways
    # Added by sa-tools
    # ANDROID_HOME is deprecated, keep for now
    # ANDROID_HOME=$HOME/Library/Android/sdk
    # ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
    # PATH="$HOME/Library/Android/sdk/tools:$HOME/Library/Android/sdk/platform-tools:$PATH"
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  #### VS Code
  programs.vscode = {
    # https://nixos.wiki/wiki/Visual_Studio_Code
  	enable = true;
  	extensions = with pkgs.vscode-extensions; [
      # Languages
      bbenoist.nix
  	  dotjoshjohnson.xml

      # Tools
  	  github.copilot      
  	  github.copilot-chat      
      eamodio.gitlens
  	];
    userSettings = {
  	  "files.autoSave" = "afterDelay";
      "git.confirmSync" = false;
      "git.autofetch" = true;
      "editor.accessibilitySupport" = "off";
      "remote.SSH.useLocalServer" = false;
      "update.mode" = "manual";
      "liveshare.anonymousGuestApproval" = "reject";
      "liveshare.guestApprovalRequired" = true;
      "liveshare.shareExternalFiles" = false;
      "workbench.colorTheme" = "SynthWave '84";
      "workbench.iconTheme" = "file-icons";
      "editor.fontFamily" = "FiraCode Nerd Font Mono";
      "terminal.integrated.fontFamily" = "FiraCode Nerd Font Mono";
      "editor.minimap.enabled" = false;
      "editor.fontSize" = "13";
      "terminal.integrated.commandsToSkipShell" = [ "-workbench.action.quickOpenView" ];
      "lldb.library" = "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB";
      "explorer.confirmDelete" = false;
      "diffEditor.ignoreTrimWhitespace" = false;
      "explorer.confirmDragAndDrop" = false;
      "editor.tabSize" = 2;
      "synthwave84.disableGlow" = true;
      "synthwave84.brightness" = 0;
      "remote.SSH.remotePlatform" = {
        "10.0.50.1" = "linux";
      };
  	};
  };

  # #### Git
  programs.git = {
    # https://nixos.wiki/wiki/git
    enable = true;
    userName = "Cooper Lewis";
    userEmail = "thatcooperlewis@gmail.com";
    extraConfig = {
      fetch.prune = true;
    };
  };

  programs.zoxide = {
    # A better `cd`
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ]; 
  };
}
