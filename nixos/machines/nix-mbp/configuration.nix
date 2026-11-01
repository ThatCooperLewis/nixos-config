{ pkgs, ... }:

{

  imports = [ ./photo-backup.nix ./lmstudio-model-schedule.nix ./stats.nix ./linux-builder.nix ./calendar-bridge.nix ./notes-mirror.nix ./windows-pc.nix ./mac-rack.nix ../darwin-base.nix ];

  system.defaults.screencapture.location = "~/Documents/screenshots";
}
