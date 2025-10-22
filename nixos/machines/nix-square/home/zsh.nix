{ config, pkgs, ... }:

{
  config.programs.zsh = {
    # https://nixos.wiki/wiki/zsh
    enable = true;
    shellAliases = {
      ll = "ls -l";
      build = "bundle exec ~/Development/ios-register/Scripts/BazelLocal/generate_xcode_project_with_bazel.rb";
      bepi = "bundle exec pod install";
      gpom = "git pull origin main";
      current = "git rev-parse --abbrev-ref HEAD";
      commit = "git commit -m";
      update = "sudo nix run nix-darwin -- switch --flake ~/nixos-config/nixos";
      snowsql = "/Applications/SnowSQL.app/Contents/MacOS/snowsql";
    };
    history.size = 30000;

    initExtra = ''
      source ${./square.zsh}
    '';

    # https://discourse.nixos.org/t/zsh-zplug-powerlevel10k-zshrc-is-readonly/30333/3
    # Source the powerlevel10k config
    # Idk what this comment is referring to
    
    oh-my-zsh = {
      enable = true;
      # zstyle ':completion:*' prevents the completion system from fucking CLI
        # zstyle ':completion:*' list-prompt   ""
        # zstyle ':completion:*' select-prompt ""
      extraConfig = ''
        ENABLE_CORRECTION="true"
        POWERLEVEL9K_MODE="nerdfont-complete"
        zstyle ':autocomplete:*' recent-dirs zoxide
      '';
      plugins = [ "git" ];
    };

    # Plugin management
    zplug = {
      enable = true;
      plugins = [
        { name = "plugins/git"; tags = [from:oh-my-zsh];}
        { name = "nvbn/thefuck";}
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "zsh-users/zsh-syntax-highlighting";}
        { name = "kevinywlui/zlong_alert.zsh";}
        { name = "djui/alias-tips";}
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
        ];
    };

    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./.;
        file = ".p10k.zsh";
      }
      {
        name = "zsh-autocomplete";
        file = "zsh-autocomplete.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          # https://github.com/marlonrichert/zsh-autocomplete
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "a76f26ae25528e76ee53df98ad38fbacdf89fd2e";
          sha256 = "sha256-o8IQszQ4/PLX1FlUvJpowR2Tev59N8lI20VymZ+Hp4w=";
        };
      }
    ];

    # Up/Down Arrow keys to search history
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "$terminfo[kcuu1]" "^[[A" ];
      searchDownKey = [ "$terminfo[kcud1]" "^[[B" ];
    };
  };
}
