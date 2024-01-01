{ config, pkgs, ...}:

{
  programs.kitty = {
    # Stolen from https://github.com/MathisP75/summer-day-and-night/blob/main/kitty/
    enable = true;
    settings = {
      font_family = "FiraCode Nerd Font";
      font_size = 11;
      cursor = "#d3c6aa";

      background = "#2d353b";
      foreground = "#d3c6aa";

      window_margin_width = 12;
      confirm_os_window_close = "-0";

      box_drawing_scale = "0.001, 1, 1.5, 2";

      selection_foreground = "#d3c6aa";
      selection_background = "#505a60";
      color0 = "#3c474d";
      color8 = "#868d80";
      color1 = "#e68183";   # red
      color9 = "#e68183";   # light red
      color2 = "#a7c080";   # green
      color10 = "#a7c080";  # light green
      color3 = "#d9bb80";   # yellow
      color11 = "#d9bb80";  # light yellow
      color4 = "#83b6af";   # blue
      color12 = "#83b6af";  # light blue
      color5 = "#d39bb6";   # magenta
      color13 = "#d39bb6";  # light magenta
      color6 = "#87c095";   # cyan
      color14 = "#87c095";  # light cyan
      color7 = "#868d80";   # light gray
      color15 = "#868d80";  # dark gray
    };
  };
}