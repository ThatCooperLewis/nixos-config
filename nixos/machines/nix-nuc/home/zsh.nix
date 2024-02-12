{ config, pkgs, ... }:

{
  config.programs.zsh = {
    # https://nixos.wiki/wiki/zsh
    enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild";
      update-home = "home-manager init --switch";
      update-monitor = "update switch --flake .#monitor-pi --target-host root@10.0.50.3 --verbose --fast"
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

    # Up/Down Arrow keys to search history
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "$terminfo[kcuu1]" "^[[B" ];
      searchDownKey = [ "$terminfo[kcud1]" "^[[A" ];
    };
  };
}
