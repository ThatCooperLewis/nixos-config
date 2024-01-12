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
  };

  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    # defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;

    # By default, NixOS will try to refer the nixosConfiguration with
    # its hostname, so the system named `nixos-test` will use this one.
    # However, the configuration name can also be specified using:
    #   sudo nixos-rebuild switch --flake /path/to/flakes/directory#<name>
    #
    # Run the following command in the flake's directory to
    # deploy this configuration on any NixOS system:
    #   sudo nixos-rebuild switch --flake .#lewis-linux
    nixosConfigurations = {
      "lewis-linux" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Set all input parameters as specialArgs of all sub-modules
        # so that we can use the `helix`(an attribute in inputs) in
        # sub-modules directly.
        specialArgs = inputs;
        modules = [
          # KVM, QEMU, and other virtualization configs
          ./virtualization.nix
          # Hardware config
          ./hardware-configuration.nix
          # All docker containers
          ./containers.nix
          # Primary configuration
          ./configuration.nix

          # make home-manager as a module of nixos
          # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
          # https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.cooper = import ./home/home.nix;
          }
        ];
      };
    };
  };
}