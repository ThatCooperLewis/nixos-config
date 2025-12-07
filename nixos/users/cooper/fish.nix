{ config, pkgs, ... }:

{
  # Make sure fish is available
  config.programs.fish = {
    enable = true;

    # Aliases / abbreviations
    shellAliases = {
      ls  = "eza --icons --group-directories-first";
      ll  = "eza -lah --icons --group-directories-first";
      la  = "eza -a --icons --group-directories-first";
      # cat = "bat";
      grep = "rg";
      # ..  = "cd ..";
      # ... = "cd ../..";
      g  = "git";
      v  = "nvim";
      
      pipes = "pipes.sh -p 3 -r 0";
      nsh = "ssh -i ~/.ssh/id_nixSSH";
      
      check = "sudo systemctl status";
      restart = "sudo systemctl restart";
      journal = "journalctl -xeu";

      update      = "sudo nixos-rebuild";
      update-darwin = "sudo nix run nix-darwin -- switch --flake ~/Nix/nixos";
      update-adguard = "update-remote adguard-pi && udpate-remote nix-remote";
      idport = "sudo netstat -tulpn | grep";
    };

    shellAbbrs = {
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull --rebase";
      mk = "mkdir -p";
      ff = "fzf";
    };

    # Plugins from nixpkgs fishPlugins
    plugins = [
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "z";        src = pkgs.fishPlugins.z.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
      { name = "done";     src = pkgs.fishPlugins.done.src; }
    ];

    # Cozy color theme + options
    interactiveShellInit = ''
      # --- Key bindings ---
      # fish_vi_key_bindings

      # --- Cozy greeting ---
      # set -g fish_greeting "🌲 Welcome back, Cooper. Take it slow."

      # --- Earthy color palette ---
      # Soft dark background, warm sand text, muted browns/greens
      set -g fish_color_normal           "#d7a97a"
      set -g fish_color_command          "#f2c38f"    # commands
      set -g fish_color_param            "#e6d5b8"
      set -g fish_color_quote            "#bfa37a"
      set -g fish_color_redirection      "#a17c5b"
      set -g fish_color_comment          "#6b4f3f"
      set -g fish_color_error            "#d47766"
      set -g fish_color_operator         "#c49c77"
      set -g fish_color_escape           "#c4af7a"
      set -g fish_color_autosuggestion   "#4b3a31"
      set -g fish_color_selection        --background="#3a2a22"
      set -g fish_color_search_match     --background="#594132"
      set -g fish_pager_color_prefix     "#f2c38f"
      set -g fish_pager_color_completion "#d7a97a"
      set -g fish_pager_color_description "#6b4f3f"

      # Background style hints to terminal (if supported)
      set -g fish_color_end              "#c49c77"
      set -g fish_pager_color_selected_background --background="#3a2a22"

      # FZF integration defaults (used by fzf-fish)
      set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --follow --glob "!.git/*"'
      set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
      set -gx FZF_DEFAULT_OPTS '--height 80% --border --layout=reverse'

      # Make prompt feel a bit slower / cozier with a subtle title
      function fish_title
        echo "$USER @ (prompt_pwd)"
      end
    '';

    # Custom cozy prompt (left + right)
    functions = {
      fish_prompt = ''
        function fish_prompt
          # Colors
          set -l sand   "#d7a97a"
          set -l bark   "#6b4f3f"
          set -l moss   "#7c9a6d"
          set -l ember  "#d47766"

          set -l cwd (prompt_pwd)
          set -l git (fish_vcs_prompt)

          # First line: user@host and cwd + git
          set_color $bark
          printf "╭─"

          set_color $sand
          printf "%s" (whoami)

          set_color $bark
          printf "@"

          set_color $sand
          printf "%s " (hostname -s)

          set_color $moss
          printf "%s" $cwd

          if test -n "$git"
            set_color $ember
            printf " %s" $git
          end

          set_color normal
          printf "\n"

          # Second line: prompt symbol
          set_color $sand
          printf "╰─❯ "
          set_color normal
        end
      '';

      fish_right_prompt = ''
        function fish_right_prompt
          set -l time (date "+%H:%M")
          set -l col "#6b4f3f"
          set_color $col
          printf "%s" $time
          set_color normal
        end
      '';
    };
  };


}