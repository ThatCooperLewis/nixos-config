{ config, pkgs, ...}:

{
  programs.waybar = {
    enable = true;
    # config = {
    #   waybar = {
    #     position = "left";
    #     modules = {
    #       "bspwm";
    #       "clock";
    #       "tray";
    #       "pulseaudio";
    #       "network";
    #       "brightness";
    #       "battery";
    #       "memory";
    #       "cpu";
    #       "temperature";
    #       "filesystem";
    #       "updates";
    #       "keyboard";
    #       "layout";
    #       "window-title";
    #     };
    #   };
    # };
  };
}