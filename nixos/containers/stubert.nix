{ lib, config, ... }:

let
  configDir = "/home/cooper/Development/stubert/config";
  claudeDir = "/home/cooper/.claude";
  claudeJson = "/home/cooper/.claude.json";
in
{
  imports = [
    ./container-base.nix
  ];

  networking.firewall.allowedTCPPorts = [ 8484 ];

  # virtualisation.oci-containers.containers.stubert = {
  #   image = "stubert:local";
  #   extraOptions = [ "--network=host" ];
  #   volumes = [
  #     "${configDir}:/data"
  #     "${claudeDir}:/root/.claude"
  #     "${claudeJson}:/root/.claude.json"
  #   ];
  # };
}
