## Unpure Commands

These commands needed to be run separately before Nix could do its thing. Maybe one day I'll figure out how to import/link them properly

- `home-manager` needed to be added to nix-channel

        sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager
        sudo nix-channel --update

- The files in this repo are all symlinked to their relevant locations. There are other ways of doing this (e.g. defining the nix config path) but I prefer this.

        home-manager init            
        rm -r ~/.config/home-manager 
        mkdir ~/.config/home-manager
        ln -s <path-to-machine-home>/home.nix ~/.config/home-manager/home.nix
        home-manager switch          

        rm -r ~/.config/hypr          # Do the same with Hyprland
        ln -s ~/Nix/hypr ~/.config

- **Backup your existing configuration.nix before this step!**

        sudo rm -rf /etc/nixos          # Delete existing configs
        sudo ln -s ~/Nix/nixos /etc     # Insert new ones

#### Misc Impurities

- VSCode's One Monokai Theme is not accesible via Nix Packages, and I'm not bothered to import it manually. Instead, I installed it in-app despite the home-manager settings already defining it. Honestly, I have no idea what happens if you set a theme that isn't installed yet. Presumably it just defaults to basic theme.

- When running nix-citizen (or star citizen via proton/lutris in general) with multiple joysticks/controllers, odds are you'll need to override their connection state in order to have them detected in-game. Running this command will open the control panel GUI for the game's specific wine instance:

        WINEPREFIX=~/Games/star-citizen nix run github:fufexan/nix-gaming#wine-ge -- control
