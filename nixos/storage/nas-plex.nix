{ lib, constants, ... }:

let 
  mountPath = constants.nfs.dirs.plex.mountPath;
  deviceSource = constants.nfs.dirs.plex.deviceSource;
in
{
  fileSystems.${mountPath} = {
    device = deviceSource;
    fsType = "nfs";
  };
}