{ pkgs, app, user, constants, ... }:

{

  config.users.users.navidrome = {
    uid = constants.users.navidrome;
    description = "Navidrome Music";
    isNormalUser = false;
    group = "navidrome";
    extraGroups = [ "wheel" ];
  };
  config.users.groups.navidrome.gid = constants.users.navidrome;
  
  config.services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      Port = constants.ports.navidrome;
      # DataFolder = "./data/appData";
      # MusicFolder = "./data/music";
      # CacheFolder = "./data/cache";
    };
  };
}
