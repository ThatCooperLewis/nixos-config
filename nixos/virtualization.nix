# Stolen mostly from https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
let
  gpuIDs = [
    "10de:2206" # RTX 3080 Graphics
    "10de:1aef" # Audio

    # "10de:1b80" # GTX 1080 Graphics
    # "10de:10f0" # Audio
  ];
in { pkgs, lib, config, ... }: {
  options.vfio.enable = with lib;
    mkEnableOption "Configure the machine for VFIO";

  config = let cfg = config.vfio;
  in {
    vfio.enable = true;
    
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        # No longer needed, built into kernel https://www.reddit.com/r/archlinux/comments/11dqiy5/vfio_virqfd_missing_in_linux621arch11/
        # "vfio_virqfd" 

        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      kernelParams = [
        # enable IOMMU
        "amd_iommu=on"
      ] ++ lib.optional cfg.enable
        # isolate the GPU
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
    };

    virtualisation.spiceUSBRedirection.enable = true; # Enable guest/host USB hotplug
    
    # From https://nixos.wiki/wiki/Virt-manager
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
  };
}

# This can be run just to check for GPU PCI IDs
# { config, lib, pkgs, modulesPath, ... }:
# {
#   
# 	boot.kernelParams = [ "amd_iommu=on" ];
# }

# She included this fun boot option so the detachment could be optional 
# However, more work would be needed to change Hyprland options, since it needs the GPU device index
# (containers --gpus option would also need to be dynamically changed)
# specialisation."VFIO".configuration = {
#   system.nixos.tags = [ "with-vfio" ];
#   vfio.enable = true;
# };