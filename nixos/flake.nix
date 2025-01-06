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
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, nix-darwin, vscode-server, home-manager, ... }: {
    
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


      "caddy-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [

          ./containers/base.nix
          # Pi-specific configuration
          ./machines/caddy-pi/configuration.nix
          # Caddy Cloudflare config 
          ./containers/cloudflare-caddy.nix
          # Tailscale VPN
          ./services/tailscale.nix
          # Cloudflare Tunnel
          ./services/cloudflare.nix

          home-manager.nixosModules.home-manager
          {
          	home-manager.useGlobalPkgs = true;
          	home-manager.useUserPackages = true;
          	home-manager.users.cooper = import ./machines/caddy-pi/home/home.nix;
          }
        ];
      };

      "monitor-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          # Generic Pi config
          ./machines/monitor-pi/configuration.nix

          ./containers/base.nix
          ./containers/uptime-kuma.nix
          ./containers/navidrome.nix

          # Telegraf metrics
          ./services/telegraf.nix
          
          # Modipy music server
          # ./services/navidrome.nix

          home-manager.nixosModules.home-manager
          {
          	home-manager.useGlobalPkgs = true;
          	home-manager.useUserPackages = true;
          	home-manager.users.cooper = import ./machines/monitor-pi/home/home.nix;
          }
        ];
      };

      "nix-nuc" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [

          ./machines/nix-nuc/hardware-configuration.nix
          ./machines/nix-nuc/configuration.nix
          
          ./containers/base.nix
          ./containers/plex-stack.nix
          # ./containers/palworld-server.nix
          ./containers/grafana.nix
          ./containers/octoprint.nix
          
          # Arr Config Backup
          ./services/plex-stack-backup.nix
          # Caddy Reverse Proxy
          # Grafana kiosk
          ./services/kiosk.nix
          # Telegraf metrics
          ./services/telegraf.nix
          # Metrics database
          ./services/influxdb.nix
          # Minecraft server
          ./services/minecraft.nix
          # Tailscale VPN
          ./services/tailscale.nix

          home-manager.nixosModules.home-manager
          {
          	home-manager.useGlobalPkgs = true;
          	home-manager.useUserPackages = true;
          	home-manager.users.cooper = import ./machines/nix-nuc/home/home.nix;
          }

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
