{ config, pkgs, ... }:

{
  config.programs.zsh = {
    # https://nixos.wiki/wiki/zsh
    enable = true;
    enableCompletion = true;

    initExtra = ''
      typeset -A nix_hosts
      nix_hosts=(
        nix-remote              5.78.156.16
        nix-brain               10.0.50.1
        nix-nuc                 10.0.50.4
        caddy-pi                10.0.50.30
        cloudflare-fallback-pi  10.0.50.31
        fortress-pi             10.0.50.33
        adguard-pi              10.0.100.0
      )

      update-remote() {
        local flake="$1"
        local ip="''${nix_hosts[$1]}"

        if [[ -z "$flake" || -z "$ip" ]]; then
          echo "Usage: update-remote <host-key>"
          echo "Known hosts: ''${(@k)nix_hosts}"
          return 1
        fi

        nixos-rebuild switch \
          --flake ~/Nix/nixos/#$flake \
          --target-host root@$ip \
          --verbose --fast
      }
    '';

    shellAliases = {
      pipes = "pipes.sh -p 3 -r 0";
      ll = "ls -l";
      nsh = "ssh -i ~/.ssh/id_nixSSH";
      
      status = "systemctl status";
      restart = "sudo systemctl restart";
      journal = "journalctl -xeu";

      update      = "sudo nixos-rebuild";
      update-darwin = "nix run nix-darwin -- switch --flake ~/Nix/nixos";

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
