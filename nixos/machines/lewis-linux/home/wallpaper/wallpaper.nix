{ config, pkgs, ...}:

{
  home.file."wallpaper/wallpaper.jpg" = {
    source = ./kalalau.jpg;
    target = "${config.home.homeDirectory}/.config/wallpaper/wallpaper.jpg";
  };
}