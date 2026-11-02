{ lib, modulesPath, ... }:

# nix-nuc on mac-rack: aarch64 VM in UTM (QEMU backend, VirtIO disks, bridged on the 10GbE).
# Disks go by label, so the install needs no UUIDs here: the OS disk is partitioned with
# NUC-BOOT (vfat) and nuc-os (ext4), and the data disk (nuc-data) is in data-disk.nix.
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "xhci_pci" "usbhid" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nuc-os";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NUC-BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ { device = "/swapfile"; size = 8192; } ];

  # The VM keeps the TrueNAS VM's MAC, so UniFi sees the same client, and the interface is
  # named by MAC so the network config doesn't depend on the host's PCI layout
  systemd.network.links."10-lan0" = {
    matchConfig.PermanentMACAddress = "00:a0:98:6d:73:87";
    linkConfig.Name = "lan0";
  };
  homeNetwork.interface = "lan0";

  services.xserver.videoDrivers = [ "modesetting" ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
