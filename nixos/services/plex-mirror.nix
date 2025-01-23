{ pkgs, app, user, lib, constants, ... }:

let 
  dataDir = constants.services.dirs.plexMirror;
in
{

  users.users.multimedia = {
    uid = 950;
    group = "multimedia";
  	description = "Plex Fallback";
  	extraGroups = [ "wheel" ];
  };
  users.groups.multimedia.gid = 950;

  # Make sure the Plex data config is properly set
  system.activationScripts.ensurePlexDataDir = lib.mkAfter ''
    mkdir -p ${dataDir}
    chown -R multimedia:multimedia ${dataDir}
  '';

  services.plex = {
    enable = true;
    openFirewall = true;
    dataDir = dataDir;
    user = "multimedia";
    group = "multimedia";
    # accelerationDevices = ["/dev/dri/renderD128"];
  };
}