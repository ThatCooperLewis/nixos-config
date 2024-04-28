{ pkgs, app, user, constants, ... }:

{
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

  systemd.timers."cloudflared" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      AccuracySec = "1h";
      Unit = "cloudflared-tunnel-4db3f32d-06ee-4104-a515-dcbbd8fdaeb6.service";
    };
  };

  services.cloudflared = {
    enable = true;
    user = "cloudflare";
    group = "cloudflare";
    tunnels = {
      "4db3f32d-06ee-4104-a515-dcbbd8fdaeb6" = {
        credentialsFile = "/var/lib/cloudflared/4db3f32d-06ee-4104-a515-dcbbd8fdaeb6.json";
        default = "http_status:404";
      };
    };
  };
}
