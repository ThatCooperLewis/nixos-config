{ config, pkgs, ...}:

# Some things stolen from https://github.com/MathisP75/summer-day-and-night

{
  
  home.file."hypr/start-applets.sh" = {
    source = ./start-applets.sh;
    target = "${config.home.homeDirectory}/.config/hypr/start-applets.sh";
  };

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.settings = {
    
    # See https://wiki.hyprland.org/Configuring/Monitors/
    # monitor= "DP-1,3440x1440@99,0x0,1";
    monitor = ",preferred,0x0,1";

    # Define which GPU to use
    # 3080 is 0b:00.0
    # 1080 is 0c:00.0
    # env = WLR_DRM_DEVICES,/dev/dri/card0

    # Calls script to run all our UI applets
    "exec-once" = "bash ~/.config/hypr/start-applets.sh";

    # everforest-light color scheme
    "$bg_dim" = "0xffefebd4";
    "$bg0" = "0xfffdf6e3";
    "$bg1" = "0xfff4f0d9";
    "$bg2" = "0xffefebd4";
    "$bg3" = "0xffe6e2cc";
    "$bg4" = "0xffe0dcc7";
    "$bg5" = "0xffbdc3af";
    "$bg_visual" = "0xffeaedc8";
    "$bg_red" = "0xfffbe3da";
    "$bg_green" = "0xfff0f1d2";
    "$bg_blue" = "0xffe9f0e9";
    "$bg_yellow" = "0xfffaedcd";
    "$fg" = "0xff5c6a72";
    "$red" = "0xfff85552";
    "$orange" = "0xfff57d26";
    "$yellow" = "0xffdfa000";
    "$green" = "0xff8da101";
    "$aqua" = "0xff35a77c";
    "$blue" = "0xff3a94c5";
    "$purple" = "0xffdf69ba";
    "$grey0" = "0xffa6b0a0";
    "$grey1" = "0xff939f91";
    "$grey2" = "0xff829181";

    general = {
      gaps_in = 8;
      gaps_out = 15;

      border_size = 2;
      "col.active_border" = "$fg";
      "col.inactive_border" = "$bg5";

      "col.nogroup_border" = "$fg";
      "col.nogroup_border_active" = "$bg5";

      resize_on_border = "true";
    
      layout = "dwindle";

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = "false";

    };

    decoration = {
      rounding = 10;

      blur = {
        enabled = "true";
        size = 3;
        passes = 1;
        new_optimizations = "on";
        xray = "true";
        ignore_opacity = "true";
      };

      # inactive_opacity = 0.93
      
      drop_shadow = "yes";
      shadow_range = 0;
      shadow_render_power = 1;
      "col.shadow" = "0xff56635f";
      "col.shadow_inactive" = "rgb(2b312f)";
      shadow_scale = 1.0;
      shadow_offset = "0 4";

      dim_inactive = "true";
      dim_strength = 0.15;

      dim_around = 0.0;
    };

    animations = {
      enabled = "yes";

      bezier =[
        "myBezier, 0.05, 0.9, 0.1, 1.05"
        "myBezier2, 0.65, 0, 0.35, 1"
        "linear, 0, 0, 1, 1"
        "slow,0,0.85,0.3,1"
        "overshot,0.7,0.6,0.1,1.1"
        "bounce,1,1.6,0.1,0.85"
        "slingshot,1,-1,0.15,1.25"
        "nice,0,6.9,0.5,-4.20"
      ];
    
      animation = [
        "windows,1,5,bounce,popin"
        "border,1,20,default"
        "fade, 1, 5, overshot"
        "workspaces, 1, 3, overshot"
        "windowsIn,1,5,slow,popin"
        "windowsMove,1,5,default"
      ];
    }; 


    # Some default env vars.
    env = "XCURSOR_SIZE,24";
    # env = WLR_NO_HARDWARE_CURSORS,1

    # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
    input = {
      kb_layout = "us";
      kb_variant = "";
      kb_model = "";
      kb_options = "";
      kb_rules = "";

      follow_mouse = 1;

      touchpad = {
        natural_scroll = "no";
      };

      sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
    };

    dwindle = {
      # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
      pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = "yes"; # you probably want this
    };

    master = {
      new_is_master = "true";
    };

    gestures = {
      workspace_swipe = "off";
    };

    misc = {
      force_default_wallpaper = 0; # Set to 0 to disable the anime mascot wallpapers
    };

    # https://wiki.hyprland.org/Configuring/Keywords/#executing
    "device:epic-mouse-v1" = {
      sensitivity = "-0.5";
    };

    # TODO: Add rule for HyprTask
    # windowrule = [
    #   "float, class:^(HyprTask)$"
    # ];
    # Example windowrule v1
    # windowrule = float, ^(kitty)$
    # Example windowrule v2
    # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
    # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more


    # See https://wiki.hyprland.org/Configuring/Keywords/ for more
    "$mainMod" = "SUPER";

    bind = [

      "$mainMod, C, exec, kitty"     # Terminal
      "$mainMod, Q, killactive,"     # Close window
      "$mainMod, M, exit,"           # Logout
      "$mainMod, E, exec, thunar"    # File manager

      # Detach from grid
      "$mainMod, V, togglefloating,"    # Toggle grid detach
      "$mainMod, P, pseudo,"            # Toggle grid resizing
      "$mainMod, J, togglesplit,"       # Flip window verticality
      "$mainMod, left, movefocus, l"    # Move window focus
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Switch workspaces with mainMod + [0-9]
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"

      # Scroll through existing workspaces 
      "$mainMod, mouse_down, workspace, e-1"
      "$mainMod, mouse_up, workspace, e+1"

      # Move between windows with arrow keys
      "CTRL ALT, left, workspace, e-1"
      "CTRL ALT, right, workspace, e+1"
      
      "$mainMod, F, exec, firefox"
      
      # Use rofi-theme-selector to change themes
      "$mainMod, Space, exec, rofi -show drun -display-drun 'Search' -show-icons -theme gruvbox-dark-soft"
    
      "Alt, Tab, exec, ~/Development/HyprTask-Qt/HyprTask next"
      "Alt Shift, Tab, exec, ~/Development/HyprTask-Qt/HyprTask back"
    ];

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    # HyprTask
    # https://github.com/ssvx/HyprTask-Qt/tree/main
    windowrulev2 = [
      "size 600 300,title:HyprTask"
      "move 100%-700 100%-400,title:HyprTask"
    ];

  };
}