{ config, pkgs, ... }:

{
  config.programs.zsh = {
    # https://nixos.wiki/wiki/zsh
    enable = true;
    enableCompletion = true;

    shellAliases = {
      pipes = "pipes.sh -p 3 -r 0";
      ll = "ls -l";
      nsh = "ssh -i ~/.ssh/id_nixSSH";
      
      update-darwin = "nix run nix-darwin -- switch --flake ~/Nix/nixos";

      update      = "sudo nixos-rebuild";
      update-caddy          = "update switch --flake ~/Nix/nixos/#caddy-pi --target-host root@10.0.50.30 --verbose --fast";
      update-caddy-fallback = "update switch --flake ~/Nix/nixos/#cloudflare-fallback-pi --target-host root@10.0.50.31 --verbose --fast";
      update-fortress       = "update switch --flake ~/Nix/nixos/#fortress-pi --target-host root@10.0.50.33 --verbose --fast";
      update-brain          = "update switch --flake ~/Nix/nixos/#nix-brain --target-host root@10.0.50.1 --verbose --fast ";
      update-nuc            = "update switch --flake ~/Nix/nixos/#nix-nuc --target-host root@10.0.50.4 --verbose --fast ";

      idport = "sudo netstat -tulpn | grep";
    };
    
    history.size = 30000;

    oh-my-zsh = {
      enable = true;
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
          rev = "762afacbf227ecd173e899d10a28a478b4c84a3f";
          sha256 = "sha256-o8IQszQ4/PLX1FlUvJpowR2Tev59N8lI20VymZ+Hp4w=";
        };
      }
    ];

    # Up/Down Arrow keys to search history
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "$terminfo[kcuu1]" "^[[B" ];
      searchDownKey = [ "$terminfo[kcud1]" "^[[A" ];
    };
  };
}
