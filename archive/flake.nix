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