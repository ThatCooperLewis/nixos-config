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

    firefox --kiosk http://10.0.50.4:3000/d/c1a342bc-6383-4d52-8485-3459d21412cf/mission-control?orgId=1&refresh=30s &
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
