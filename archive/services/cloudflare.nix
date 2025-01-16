
  # TODO: Why did I do this? What was the purpose?
  # Removed since we're now running plex through this tunnel
  # systemd.timers."cloudflared" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #     AccuracySec = "1h";
  #     Unit = "cloudflared-tunnel-4db3f32d-06ee-4104-a515-dcbbd8fdaeb6.service";
  #   };
  # };
