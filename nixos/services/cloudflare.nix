{ lib, constants, ... }:

let
  tunnelId = "4db3f32d-06ee-4104-a515-dcbbd8fdaeb6";
  source = "${constants.nfs.dirs.secrets.mountPath}/cloudflare/credentials.json";
in
{
  imports = [
    ../storage/nas-secrets.nix
  ];

  # Copy the Cloudflare credentials from the NAS before the tunnel starts, on every boot and deploy.
  # If the NAS is unreachable, keep the last copy so the tunnel still comes up.
  systemd.services.cloudflare-credentials = {
    description = "Copy Cloudflare tunnel credentials from the NAS";
    wantedBy = [ "multi-user.target" ];
    before = [ "cloudflared-tunnel-${tunnelId}.service" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "60s";
    };
    script = ''
      mkdir -p /var/lib/cloudflared
      if cp ${source} /var/lib/cloudflared/credentials.json.new; then
        mv /var/lib/cloudflared/credentials.json.new /var/lib/cloudflared/credentials.json
      else
        rm -f /var/lib/cloudflared/credentials.json.new
        echo "NAS credentials unavailable, keeping the existing copy" >&2
      fi
      chown -R ${toString constants.users.cloudflare}:${toString constants.users.cloudflare} /var/lib/cloudflared
    '';
  };
  systemd.services."cloudflared-tunnel-${tunnelId}" = {
    wants = [ "cloudflare-credentials.service" ];
    after = [ "cloudflare-credentials.service" ];
  };

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
    tunnels = {
      ${tunnelId} = {
        credentialsFile = "/var/lib/cloudflared/credentials.json";
        default = "http_status:404";
      };
    };
  };
}
