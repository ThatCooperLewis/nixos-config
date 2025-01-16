{ lib, constants, ... }:

{
  imports = [
    ../storage/nas-secrets.nix
  ];

  # Copy the Cloudflare credentials from NAS
  system.activationScripts.populateCaddyEnv = lib.mkAfter ''
      mkdir -p /var/lib/cloudflared
      chown -R ${toString constants.users.cloudflare}:${toString constants.users.cloudflare} /var/lib/cloudflared
      cp /mnt/nas-secrets/cloudflare/credentials.json /var/lib/cloudflared/credentials.json
  '';

  users = {
    users.cloudflare = {
      isSystemUser = true;
      uid = constants.users.cloudflare;
      group = "cloudflare";
      description = "Cloudflared Tunnel";
      extraGroups = [ "wheel" ]; 
    };
    groups.cloudflare.gid = constants.users.cloudflare;
  };

  services.cloudflared = {
    enable = true;
    user = "cloudflare";
    group = "cloudflare";
    tunnels = {
      "4db3f32d-06ee-4104-a515-dcbbd8fdaeb6" = {
        credentialsFile = "/var/lib/cloudflared/credentials.json";
        default = "http_status:404";
      };
    };
  };
}
