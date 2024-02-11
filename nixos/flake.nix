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
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, vscode-server, home-manager, ... }: {
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

      "monitor-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          # Generic Pi config
          ./machines/monitor-pi/configuration.nix

          ./containers/base.nix
          ./containers/influxdb.nix
          
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
          ./containers/uptime-kuma.nix
          ./containers/palworld-server.nix
          ./containers/grafana.nix
          ./containers/telegraf.nix
          
          # Caddy Reverse Proxy
          ./services/reverse-proxy.nix
          # Cloudflared Tunnel
          ./services/cloudflare.nix
          # Cage is failing... unsure why... wayland issues?
          # ./services/kiosk.nix

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
    };
  };
}
