{ pkgs, app, user, ... }:

{
  services.cloudflared = {
    enable = true;
    user = "cloudflare";
    group = "cloudflare";
    tunnels = {
      "4db3f32d-06ee-4104-a515-dcbbd8fdaeb6" = {
        # TODO: Find better way to define this
        credentialsFile = "/var/lib/cloudflared/4db3f32d-06ee-4104-a515-dcbbd8fdaeb6.json";
        default = "http_status:404";
      };
    };
  };
}
