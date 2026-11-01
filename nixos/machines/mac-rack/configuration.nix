{ constants, ... }:

# The rack M3 Pro MacBook: Plex server and VM host. See Brain Wiki/Mac Rack.
{

  imports = [ ../darwin-base.nix ./power.nix ./network.nix ];

  networking.hostName = "mac-rack";
  networking.computerName = "mac-rack";
  networking.localHostName = "mac-rack";

  # Managed remotely over SSH (macOS Remote Login, enabled by users/cooper/user.nix)
  users.users.cooper.openssh.authorizedKeys.keys = constants.sshKeys;
  # Keys only. sshd takes the first value it reads, and these load before the
  # macOS defaults in /etc/ssh/sshd_config.
  services.openssh.extraConfig = ''
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';

  # A server: macOS updates get installed by hand, not at 3am
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
}
