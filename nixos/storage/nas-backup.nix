{ lib, constants, ... }:

let 
  mountPath = constants.nfs.dirs.backup.mountPath;
  deviceSource = constants.nfs.dirs.backup.deviceSource;
in
{
  fileSystems.${mountPath} = {
    device = deviceSource;
    fsType = "nfs";
  };
}