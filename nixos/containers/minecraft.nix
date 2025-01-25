{ lib, constants, ... }:

let
  dataDir = constants.docker.dirs.minecraft;
  docker = constants.docker;
in
{

  imports = [
    ./container-base.nix
  ];

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

  networking.firewall.allowedTCPPorts = [ 19132 ];
  networking.firewall.allowedUDPPorts = [ 19132 ];

  system.activationScripts.ensureMinecraftDataDir = lib.mkAfter ''
      mkdir -p ${dataDir}
      chown -R ${docker.users.minecraft}:${docker.users.minecraft} ${dataDir}
  '';

  virtualisation.oci-containers.containers = {
    minecraft = {
      environment = {
        UID = "${docker.users.minecraft}";
        GID = "${docker.users.minecraft}";
        ALLOW_CHEATS = "true";
        EULA = "TRUE";
        DIFFICULTY = "1";
        GAMEMODE = "creative";
        SERVER_NAME = "Lewis Minecraft";
        LEVEL_SEED = "-5584399987456711267";
        TZ = "America/Los_Angeles";
        VERSION = "1.21.51";
        ALLOW_LIST_USERS = "Sirfwinklee,chikkynuggy2232,frogallergy";
      };
      image = "itzg/minecraft-bedrock-server";
      ports = ["19132:19132/udp"];
      volumes = [ "${docker.dirs.minecraft}/bedrock:/data" ];
    };
  };
}