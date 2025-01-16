{ lib, ... }:

{
  fileSystems."/mnt/nas-secrets" = {
    device = "10.0.50.2:/mnt/tahani/secrets";
    fsType = "nfs";
  };
}