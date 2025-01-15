{ config, lib, pkgs, inputs, constants, ... }:

let
  ubuntuServer2410 = pkgs.fetchurl {
    url = "https://releases.ubuntu.com/24.10/ubuntu-24.10-live-server-amd64.iso";
    sha256 = "0isc5hdya23a416qii99zxma7sa5g25hzam4dm1f7nz5ll17rkjg";
  };
in
{
  services.proxmox-ve.vms = {
      omada-controller = {
        vmid = 100;
        memory = 2048;
        cores = 2;
        sockets = 1;
        kvm = true;
        net = [
          {
            model = "virtio";
            bridge = "vmbr0";
          }
        ];
        scsi = [ { file = "/mnt/vm-storage-alpha/omada-controller-disk.qcow2"; } ];
      };
  };
}