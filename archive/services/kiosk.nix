{ pkgs, constants, ... }:

#############################
####### GRAFANA KIOSK #######
#############################

/*

Rotates vertical screen and boots into Grafana dashboard

*/

let

  browser = pkgs.firefox;
  autostart = ''
    #!${pkgs.bash}/bin/bash

    xrandr --output HDMI-1 --rotate right
    
    xset -dpms     # Disable DPMS (Energy Star) features
    xset s off     # Disable screensaver
    xset s noblank # Don't blank video device

    # Give the computer time to connect to network
    sleep 5

    # Hide mouse cursor
    unclutter -idle 0.5 -root &

    # Load grafana dash
    firefox --kiosk ${constants.urls.grafana}/d/c1a342bc-6383-4d52-8485-3459d21412cf/mission-control?orgId=1&refresh=30s &
  '';

  inherit (pkgs) writeScript;

in {

  services.xserver = {
    # Start openbox after autologin
    windowManager.openbox.enable = true;
    displayManager.defaultSession = "none+openbox";
  };

  # Overlay to set custom autostart script for openbox
  nixpkgs.overlays = with pkgs; [
    (self: super: {
      openbox = super.openbox.overrideAttrs (oldAttrs: rec {
        postFixup = ''
          ln -sf /etc/openbox/autostart $out/etc/xdg/openbox/autostart
        '';
      });
    })
  ];

  # By defining the script source outside of the overlay, we don't have to
  # rebuild the package every time we change the startup script.
  environment.etc."openbox/autostart".source = writeScript "autostart" autostart;
}
