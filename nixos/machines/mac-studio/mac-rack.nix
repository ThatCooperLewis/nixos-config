{ ... }:

# SSH alias for the rack M3 Pro MacBook (`ssh mac-rack`). Uses the IP from
# constants.nix rather than mac-rack.local: mDNS also answers with its Wi-Fi
# address, and won't cross VLANs if it moves to Homelab. mac-rack only accepts
# keys in constants.sshKeys, and this Mac's key there is id_nixSSH.

let
  constants = import ../../constants.nix;
in
{
  programs.ssh.extraConfig = ''
    Host mac-rack
      HostName ${constants.ips.macRack}
      User cooper
      IdentityFile /Users/cooper/.ssh/id_nixSSH
      IdentitiesOnly yes
  '';
}
