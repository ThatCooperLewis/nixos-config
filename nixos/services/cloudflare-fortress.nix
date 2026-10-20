{ config, ... }:

/*

fortress-pi's own Cloudflare tunnel, so public Overseerr traffic doesn't pass through the shared tunnel on caddy-pi/fallback-pi.
Routes are managed in the Cloudflare dashboard (requests.lewisho.me -> localhost:5055).

The credentials come from secrets/fortress-pi-tunnel.age (agenix), not the NAS secrets share: this Pi must not reach the NAS
or hold the shared tunnel's credentials. agenix decrypts it at activation with the Pi's SSH host key into /run/agenix.
To recreate the secret, fetch the tunnel token from the Cloudflare API (cfd_tunnel/<id>/token), base64-decode it,
and encrypt {AccountTag, TunnelID, TunnelSecret} with `agenix -e fortress-pi-tunnel.age` (run in secrets/).

*/

{
  age.secrets.fortress-pi-tunnel.file = ../secrets/fortress-pi-tunnel.age;

  services.cloudflared = {
    enable = true;
    tunnels."e9182e1a-464f-4c38-916e-68ed36cdb1be" = {
      credentialsFile = config.age.secrets.fortress-pi-tunnel.path;
      default = "http_status:404";
    };
  };
}
