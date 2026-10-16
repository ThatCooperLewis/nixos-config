{ ... }:

/*

fortress-pi's own Cloudflare tunnel, so public Overseerr traffic doesn't pass through the shared tunnel on caddy-pi/fallback-pi.
Routes are managed in the Cloudflare dashboard (requests.lewisho.me -> localhost:5055).

The credentials file is placed on the Pi by hand, not copied from the NAS secrets share: this Pi must not reach the NAS
or hold the shared tunnel's credentials. To recreate it, fetch the tunnel token from the Cloudflare API
(cfd_tunnel/<id>/token), base64-decode it, and write {AccountTag, TunnelID, TunnelSecret} to the path below, mode 600.

*/

{
  services.cloudflared = {
    enable = true;
    tunnels."e9182e1a-464f-4c38-916e-68ed36cdb1be" = {
      credentialsFile = "/var/lib/cloudflared/fortress-pi.json";
      default = "http_status:404";
    };
  };
}
