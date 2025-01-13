{ config, pkgs, ...}:

{
  home.file."wallpaper/wallpaper.jpg" = {
    source = ./ferns.jpg;
    target = "${config.home.homeDirectory}/.config/wallpaper/wallpaper.jpg";
  };
}