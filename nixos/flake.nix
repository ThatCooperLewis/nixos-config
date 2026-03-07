# https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
# Generate an example flake of all options with `nix flake init -t templates#full`
{
  description = "A flawless, error-free NixOS configuration. Guys want to be her. Girls also want to be her.";

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Unstable branch
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";    
    };

    # https://www.nyx.chaotic.cx/
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # https://github.com/LovingMelody/nix-citizen/
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
    
    # https://github.com/nix-community/nixos-vscode-server
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # https://github.com/GuillaumeDesforges/fix-python
    fix-python.url = "github:GuillaumeDesforges/fix-python";

    # https://github.com/sadjow/claude-code-nix
    claude-code.url = "github:sadjow/claude-code-nix?ref=latest";

    # macOS flakes
    # https://nixcademy.com/posts/nix-on-macos/
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    # https://github.com/LnL7/nix-darwin
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    # Enable determinate build for mac-server
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, chaotic, nix-darwin, nixpkgs-darwin, vscode-server, home-manager, claude-code, ... }: {
    
    # macOS machines
    darwinConfigurations = let
      # TODO: Combine both the constants imports at the higher-level `outputs` declaration
      constants = import ./constants.nix;
    in {

      # Personal MacBook
      cooper-mbp = nix-darwin.lib.darwinSystem {
        system.configurationRevision = self.rev or self.dirtyRev or null;
        modules = [

          ./machines/nix-mbp/configuration.nix

          home-manager.darwinModules.home-manager
          ./users/cooper/user.nix

        ];
      };

      # Mac Server
      mac-server = nix-darwin.lib.darwinSystem {
        system.configurationRevision = self.rev or self.dirtyRev or null;
        modules = [
          inputs.determinate.darwinModules.default
          
          ./machines/nix-mac/configuration.nix

          home-manager.darwinModules.home-manager
          ./users/cooper/user.nix

        ];
      };
    };

    # nixOS machines
    nixosConfigurations = let
      constants = import ./constants.nix;
    in {

      "adguard-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/pi-base.nix
          {
            raspberryPi.enable = true;
            raspberryPi.hostname = "adguard-pi";
            raspberryPi.address = "10.0.100.0";
          }

          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./services/tailscale.nix
          ./services/adguard.nix
        ];
      };

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

          ./containers/caddy.nix

          ./services/tailscale.nix
          ./services/cloudflare.nix
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

          ./services/cloudflare.nix
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

          ./containers/overseerr.nix
        ];
      };

      "nix-nuc-old" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/nix-nuc/configuration.nix
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          # ./containers/arr-stack.nix
          
          # ./services/telegraf.nix
          ./services/tailscale.nix
          # ./services/geocities-portfolio.nix

          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };

      "nix-nuc" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ claude-code.overlays.default ];
            environment.systemPackages = [ pkgs.claude-code ];
          })
          ./machines/nix-nas/configuration.nix
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./containers/arr-stack.nix
          ./services/stubert.nix
          
          # ./services/telegraf.nix
          ./services/tailscale.nix
          ./services/geocities-portfolio.nix

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

          ./containers/omada-controller.nix
          ./containers/grafana.nix
          ./containers/minecraft.nix

          ./services/plex-mirror.nix
          ./services/tailscale.nix
          ./services/cloudflare.nix
          ./services/influxdb.nix
          ./services/telegraf.nix
          ./services/remote-desktop.nix

          ./programs/vuescan/vuescan.nix
          
          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };

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

      "nix-remote" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
        specialArgs = { inherit inputs constants; };
        modules = [
          ./machines/nix-remote/configuration.nix
          
          home-manager.nixosModules.home-manager
          ./users/cooper/user.nix
          ./users/root/ssh.nix

          ./services/tailscale.nix
          ./services/adguard.nix

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
