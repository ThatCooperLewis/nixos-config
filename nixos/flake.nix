# https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
# Generate an example flake of all options with `nix flake init -t templates#full`
{
  description = "A flawless, error-free NixOS configuration. Guys want to be her. Girls also want to be her.";

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";    
    };

    # Star Citizen
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    # Optional - updates underlying without waiting for nix-citizen to update
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
    
    # https://github.com/nix-community/nixos-vscode-server
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    fix-python.url = "github:GuillaumeDesforges/fix-python";

    # macOS flakes
    # https://nixcademy.com/2024/01/15/nix-on-macos/
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Proxmox VE
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, nix-darwin, vscode-server, home-manager, proxmox-nixos, ... }: {
    
    # macOS machines
    darwinConfigurations = let
      # TODO: Combine both the constants imports at the higher-level `outputs` declaration
      constants = import ./constants.nix;
    in {
      # Square-issued M3 MBP
      "BLKKTWPFQ13Y2" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit self inputs; };
        modules = [ 

          ./machines/nix-square/configuration.nix
        
          home-manager.darwinModules.home-manager
          {
            # nixpkgs = nixpkgsConfig;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.cooperl = import ./machines/nix-square/home/home.nix;
          }
        ];
      };
    };

    # nixOS machines
    nixosConfigurations = let
      constants = import ./constants.nix;
    in {

      "caddy-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/pi-base.nix
          {
            raspberryPi.enable = true;
            raspberryPi.hostname = "caddy-pi";
            raspberryPi.swapSize = 16;
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./containers/base.nix
          # Caddy Reverse Proxy 
          ./containers/caddy.nix
          # Tailscale VPN
          ./services/tailscale.nix
          # Cloudflare Tunnel
          ./services/cloudflare.nix
          # Metrics emitter
          ./services/telegraf.nix

        ];
      };

      "cloudflare-fallback-pi" = nixpkgs.lib.nixosSystem {
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
            raspberryPi.swapSize = 16;
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          # Cloudflare Tunnel
          ./services/cloudflare.nix
          # Metrics emitter
          ./services/telegraf.nix

        ];
      };

      "fortress-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/pi-base.nix
          {
            raspberryPi.enable = true;
            raspberryPi.hostname = "fortress-pi";
            raspberryPi.swapSize = 16;
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./containers/base.nix
          # Overseerr - Public website
          ./containers/overseerr.nix

        ];
      };

      "nix-nuc" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/nix-nuc/configuration.nix
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./containers/base.nix
          ./containers/plex-stack.nix
          ./containers/octoprint.nix
          
          # Telegraf metrics
          ./services/telegraf.nix
          # Minecraft server
          ./services/minecraft.nix
          # Tailscale VPN
          ./services/tailscale.nix
          # Arr Config Backup
          ./backups/backup-arr-stack.nix

          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };


      "nix-brain" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/nix-brain/configuration.nix
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix

          ./containers/base.nix
          # Omada Wifi Controller
          ./containers/omada-controller.nix
          # Metrics dashboard
          ./containers/grafana.nix
          # Tailscale VPN
          ./services/tailscale.nix
          # Cloudflare Tunnel
          ./services/cloudflare.nix
          # Driving monitoring
          ./services/influxdb.nix
          # Metrics emitter
          ./services/telegraf.nix

          ./backups/mirror-plex-data.nix

          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };

      # ISO File Builds

      raspIso = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";
        modules = [
          ({ pkgs, modulesPath, ... }: {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
          })

          ./templates/raspi-4/configuration.nix
        ];
      };
    };
  };
}
