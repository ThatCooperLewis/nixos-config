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
      update = "nix run nix-darwin -- switch --flake ~/nixos-config/nixos";
    };
    history = {
    	size = 30000;
      # path = "${config.xdg.dataHome}/zsh/history";
    };

    # https://discourse.nixos.org/t/zsh-zplug-powerlevel10k-zshrc-is-readonly/30333/3
    # Source the powerlevel10k config
    initExtra = ''
      [[ ! -f ${./p10k.zsh} ]] || source ${./p10k.zsh}
      source ${./sq.zsh}
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

    # Up/Down Arrow keys to search history
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "$terminfo[kcuu1]" "^[[A" ];
      searchDownKey = [ "$terminfo[kcud1]" "^[[B" ];
    };
  };
}
