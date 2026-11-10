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


## Raspberry Pis, retired 2026-11-09 (services moved to nix-nuc and TrueNAS VMs; see Brain Projects/Hardware Consolidation Plan)
## They used archive/machines/pi-base.nix (was machines/pi-base.nix) and the nixpkgs-pi / home-manager-pi inputs.
## Removed constants: ips.caddyPi 10.50.0.30, ips.fallbackPi 10.50.0.31, ips.adguard 10.50.0.32,
## tails.caddypi 100.69.31.128, tails.adguard 100.124.121.82, ports.adguard 3003 (archive/services/adguard.nix uses it).

      "adguard-pi" = inputs.nixpkgs-pi.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/pi-base.nix
          {
            raspberryPi.enable = true;
            raspberryPi.hostname = "adguard-pi";
            raspberryPi.address = "10.50.0.32";
            # Homelab (VLAN 50); see Brain Wiki/Home Network
            homeNetwork.gateway = "10.50.0.1";
            homeNetwork.prefixLength = 24;
          }

          inputs.home-manager-pi.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./services/tailscale.nix
          ./services/adguard.nix
        ];
      };

      "caddy-pi" = inputs.nixpkgs-pi.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/pi-base.nix
          {
            raspberryPi.enable = true;
            raspberryPi.hostname = "caddy-pi";
            raspberryPi.address = "10.50.0.30";
            # Homelab (VLAN 50); see Brain Wiki/Home Network
            homeNetwork.gateway = "10.50.0.1";
            homeNetwork.prefixLength = 24;
          }

          inputs.home-manager-pi.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./containers/caddy.nix

          ./services/tailscale.nix
          ./services/cloudflare.nix
          ./services/telegraf.nix

        ];
      };

      "cloudflare-fallback-pi" = inputs.nixpkgs-pi.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { 
          inherit inputs constants; 
          systemType = "aarch64-linux"; 
        };
        modules = [
          # Use the default RaspberryPi configuration
          ./machines/pi-base.nix
          {
            raspberryPi.enable = true;
            raspberryPi.hostname = "cloudflare-fallback-pi";
            raspberryPi.address = "10.50.0.31";
            # Homelab (VLAN 50); see Brain Wiki/Home Network
            homeNetwork.gateway = "10.50.0.1";
            homeNetwork.prefixLength = 24;
          }

          inputs.home-manager-pi.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./services/cloudflare.nix
          ./services/telegraf.nix
          ./services/tailscale.nix
        ];
      };
