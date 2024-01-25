{ pkgs, app, user, ... }:

{
  services.cage.enable = true;
  services.cage.program = "${pkgs.firefox}/bin/firefox -kiosk https://apple.com";
  services.cage.user = "kiosk";
}
