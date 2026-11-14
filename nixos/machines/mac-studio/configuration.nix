{ pkgs, ... }:

{

  imports = [ ./photo-backup.nix ./lmstudio-model-schedule.nix ./stats.nix ./linux-builder.nix ./calendar-bridge.nix ./notes-mirror.nix ./windows-pc.nix ./ssh-hosts.nix ./network-switch.nix ../darwin-base.nix ];

  networking.hostName = "mac-studio";
  networking.computerName = "mac-studio";
  networking.localHostName = "mac-studio";

  system.defaults.screencapture.location = "~/Documents/screenshots";
}
