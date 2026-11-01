## Old primary linux machine, living but unused

      "lewis-linux" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Set all input parameters as specialArgs of all sub-modules
        # so that we can use the `helix`(an attribute in inputs) in
        # sub-modules directly.
        specialArgs = { inherit inputs constants; };
        modules = [
          # Hardware config
          ./machines/lewis-linux/hardware-configuration.nix
          # Primary configuration
          ./machines/lewis-linux/configuration.nix
          # KVM, QEMU, and other virtualization configs
          ./virtualization.nix
          # All docker containers
          ./containers/containers.nix
          # Telegraf metrics
          ./services/telegraf.nix

          # make home-manager as a module of nixos
          # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
          # https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.cooper = import ./machines/lewis-linux/home/home.nix;
          }

          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };



# Attempt at using proxmox-nixos
      "proxmox-brain" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/proxmox-brain/configuration.nix
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          proxmox-nixos.nixosModules.proxmox-ve
          ./virtualization/proxmox.nix

          ./virtualization/vm/omada-controller.nix

          # Tailscale VPN
          ./services/tailscale.nix
        ];
      };



# Gaming workstation: CachyOS kernel, HDR, Steam, Star Citizen, Ollama. Archived 2026-11-01.
# Needs these flake inputs:
#   nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
#   chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";       # https://www.nyx.chaotic.cx/
#   nix-citizen.url = "github:LovingMelody/nix-citizen";          # https://github.com/LovingMelody/nix-citizen/
#   nix-gaming.url = "github:fufexan/nix-gaming";
#   nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
      "nix-game" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit nixpkgs-unstable inputs constants; };
        modules = [
          ./machines/nix-game/configuration.nix
          chaotic.nixosModules.default
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./services/tailscale.nix
          # ./services/remote-desktop.nix
          
          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };
