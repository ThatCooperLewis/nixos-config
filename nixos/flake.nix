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
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      "lewis-linux" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Set all input parameters as specialArgs of all sub-modules
        # so that we can use the `helix`(an attribute in inputs) in
        # sub-modules directly.
        specialArgs = {inherit inputs;};
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
        ];
      };

      "monitor-pi" = nixpkgs.lib.nixosSystem {
      	system = "aarch64-linux";

        specialArgs = {inherit inputs;};
        modules = [
          # Generic Pi config
          ./machines/monitor-pi/configuration.nix

          ./containers/tig-stack.nix
          
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
        specialArgs = {inherit inputs;};
        modules = [

          ./machines/nix-nuc/hardware-configuration.nix
          ./machines/nix-nuc/configuration.nix
          ./containers/plex-stack.nix

          home-manager.nixosModules.home-manager
          {
          	home-manager.useGlobalPkgs = true;
          	home-manager.useUserPackages = true;
          	home-manager.users.cooper = import ./machines/nix-nuc/home/home.nix;
          }
        ];
      };
    };
  };
}
