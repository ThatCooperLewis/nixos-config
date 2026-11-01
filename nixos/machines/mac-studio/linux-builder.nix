{ ... }:

# Small NixOS VM that builds aarch64-linux natively, so Pi configs (and their
# kernels) don't have to compile under emulation on nix-nuc. Determinate's own
# native Linux builder needs FlakeHub early access, so this is the nixpkgs one.
{
  determinateNix.nixosVmBasedLinuxBuilder = {
    enable = true;
    # Keep the builder's store between restarts so rebuilds stay fast
    ephemeral = false;
    config.virtualisation = {
      cores = 8;
      darwin-builder = {
        memorySize = 16 * 1024;
        diskSize = 80 * 1024;
      };
    };
  };
}
