{ config, pkgs, ...}:

{
  # xdg.configFile."waybar/style.css" = ../waybar/style.css;
  # xdg.configFile."waybar/mocha.css" = ../waybar/mocha.css;

  # Helpful links
  # https://github.com/georgewhewell/nixos-host/blob/master/home/waybar.nix
  # https://github.com/MathisP75/summer-day-and-night/blob/main/waybar/everforest/config

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      ${builtins.readFile "/home/cooper/Nix/waybar/forest-style.css"}
      * {
        font-family: JetBrainsMono Nerd Font, FontAwesome;
        
        /* Prevent modules from forcing a thicc taskbar */
        font-size: 14px;
        min-height: 0px;
      }
    '';
    settings = [{
      layer= "top";
      position = "top";
      height = 10;
      
      margin-top = 0;
      margin-bottom = 0;
      margin-left = 100;
      margin-right = 100;

      spacing = 15;

      modules-left = ["custom/launcher" "clock" "clock#date"];
      modules-center = ["hyprland/workspaces"];
      modules-right = ["custom/music" "network" "cpu" "memory" "temperature" "custom/powermenu" ];

      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };      

      memory = { format = "{}% "; };

      "hyprland/workspaces" = {
        disable-scroll = true;
        # format = "  {}";
        # escape = true;
        # interval = 1;
        all-outputs = true;
        separate-outputs = true;
        # on-click = "bspc desktop -f '^{index}'";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        persistent-workspaces = {
          "1" = [];
          "2" = [];
          "3" = [];
          "4" = [];
          "5" = [];
        };
      };

      "custom/launcher" = {
        interval = "once";
        format = "󰣇";
        on-click = "rofi -show drun -show-icons";
        tooltip = false;
      };

      "custom/music" = {
        format = "  {}";
        escape =  true;
        interval = 3;
        tooltip = false;
        exec = "playerctl metadata --format='{{ title }} - {{ artist }}'";
        on-click = "playerctl play-pause";
        max-length = 60;
      };

      "custom/powermenu" = {
        format = "";
        on-click = "pkill rofi || sh .config/wofi/scripts/powermenu.sh 'everforest-light' '--height=17% -o $MAIN_DISPLAY'";
        tooltip = false;
      };

      network = {
          format-ethernet = " up: {bandwidthUpBits} down: {bandwidthDownBits}";
          format-disconnected = "󰤭";
            # on-click = "sh ~/.config/wofi/scripts/wifimenu.sh";
      };

      "clock" = {
        format = " {:%H:%M}";
      };

      "clock#date" = {
        format = " {:%A, %B %d, %Y}";
      };

      temperature = {
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        format-icons = [ "" ];
      };
    }];
  };
}