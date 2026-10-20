{ lib, constants, ... }:

let 
  mountPath = constants.nfs.dirs.secrets.mountPath;
  deviceSource = constants.nfs.dirs.secrets.deviceSource;
in
{
  fileSystems.${mountPath} = {
    device = deviceSource;
    fsType = "nfs";
    # Fail fast instead of hanging when the NAS is unreachable: mount on first
    # access, never block boot, and return errors rather than retrying forever
    options = [
      "x-systemd.automount"
      "x-systemd.mount-timeout=10s"
      "nofail"
      "soft"
      "timeo=50"
      "retrans=2"
    ];
  };
}