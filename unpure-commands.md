## Unpure Commands

To my knowledge, these commands needed to be run separately before Nix could be fully pure

- `home-manager` needed to be added to nix-channel

        sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager
        sudo nix-channel --update

- The files in this repo are all symlinked to their relevant locations. There are other ways of doing this (e.g. defining the nix config path) but I prefer this.

        home-manager init                           # Initialize for first time
        rm ~/.config/home-manager/home.nix          # Delete default config
        ln -s ~/Nix/home ~/.config/home-managaer     # Symlink home/ dir from repo
        home-manager switch                         # Build with new config

- **Backup your existing configuration.nix before this step!**

        sudo rm -rf /etc/nixos          # Delete existing configs
        sudo ln -s ~/Nix/nixos /etc     # Insert new ones

#### Misc Impurities

- VSCode's One Monokai Theme is not accesible via Nix Packages, and I'm not bothered to import it manually. Instead, I installed it in-app despite the home-manager settings already defining it. Honestly, I have no idea what happens if you set a theme that isn't installed yet. Presumably it just defaults to basic theme.