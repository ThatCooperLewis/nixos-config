# https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
# Generate an example flake of all options with `nix flake init -t templates#full`
{
  description = "A flawless, error-free NixOS configuration. Guys want to be her. Girls also want to be her.";

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";    
    };

    # https://github.com/LovingMelody/nix-citizen/
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
    
    # https://github.com/nix-community/nixos-vscode-server
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # https://github.com/GuillaumeDesforges/fix-python
    fix-python.url = "github:GuillaumeDesforges/fix-python";

    # macOS flakes
    # https://nixcademy.com/posts/nix-on-macos/
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    # https://github.com/LnL7/nix-darwin
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, nix-darwin, nixpkgs-darwin, vscode-server, home-manager, ... }: {
    
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

      cooper-mbp = nix-darwin.lib.darwinSystem {
        system.configurationRevision = self.rev or self.dirtyRev or null;
        modules = [

          ./machines/nix-mbp/configuration.nix

          home-manager.darwinModules.home-manager
          ./users/cooper/user.nix

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
            raspberryPi.address = "10.0.50.30";
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

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
            raspberryPi.address = "10.0.50.31";
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          # Cloudflare Tunnel
          ./services/cloudflare.nix
          # Metrics emitter
          ./services/telegraf.nix

          ./services/tailscale.nix


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
            raspberryPi.address = "10.0.50.33";
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

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

          ./containers/plex-stack.nix
          ./containers/octoprint.nix
          
          # Telegraf metrics
          ./services/telegraf.nix
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
          ./users/root/ssh.nix

          # Omada Wifi Controller
          ./containers/omada-controller.nix
          # Metrics dashboard
          ./containers/grafana.nix
          # Minecraft server
          ./containers/minecraft.nix

          # Plex Fallback
          ./services/plex-mirror.nix
          # Tailscale VPN
          ./services/tailscale.nix
          # Cloudflare Tunnel
          ./services/cloudflare.nix
          # Driving monitoring
          ./services/influxdb.nix
          # Metrics emitter
          ./services/telegraf.nix

          ./services/remote-desktop.nix

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
