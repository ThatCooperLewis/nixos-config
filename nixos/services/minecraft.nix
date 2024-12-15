{ pkgs, app, user, constants, ... }:

{

  users = {
    users.minecraft = {
      isSystemUser = true;
      uid = constants.users.minecraft;
      group = "minecraft";
      description = "Minecraft server service user";
      extraGroups = [ "wheel" ]; 
    };
    groups.minecraft.gid = constants.users.minecraft;
  };

  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    declarative = true;
    dataDir = constants.docker.dirs.minecraft;
    serverProperties = {
      server-port = constants.ports.minecraft;
      gamemode = "creative";
      level-seed = " -5584399987456711267";
    };
  };
}