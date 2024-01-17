# Stolen mostly from Astrid https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
# Also some config things for easy anti-cheat https://forums.unraid.net/topic/127639-easy-anti-cheat-launch-error-cannot-run-under-virtual-machine/
# Guide on how to do this https://www.reddit.com/r/VFIO/comments/iv1yjb/setting_up_vfio_in_nixos/
let
  gpuIDs = [
    # "10de:2206" # RTX 3080 Graphics
    # "10de:1aef" # Audio

    # "8086:1539" # 1gig Ethernet (host keeps 2.5gig port)

    # "15b7:5017" # NVMe SSD (VM boot drive)

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
        # "virtiofsd" # https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752

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

    # Per Arch Wiki audio passthrough, tells qemu which users audio to pass through
    virtualisation.libvirtd.extraConfig = "user = \"cooper\"";

    # From https://nixos.wiki/wiki/Virt-manager
    virtualisation.libvirtd = {
      enable = true;
      # Guide to skip Win 11 TPM check during install: https://www.tomshardware.com/how-to/bypass-windows-11-tpm-requirement
      qemu.swtpm.enable = true;
    };
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
