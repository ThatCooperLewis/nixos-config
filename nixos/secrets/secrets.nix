# agenix recipients: which public keys can decrypt each secret. Not imported by any machine.
# Edit a secret:  cd ~/Nix/nixos/secrets && nix run github:ryantm/agenix -- -e <name>.age
# After changing keys here (e.g. a reinstalled host has a new host key):  nix run github:ryantm/agenix -- -r
let
  # Cooper's ~/.ssh/id_ed25519, so secrets can always be edited from the Mac
  cooper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9dBYcueY75DBHGBW10FlYz7alzlPznCkJKe6/aPiJw";

  # Host keys: /etc/ssh/ssh_host_ed25519_key.pub on each machine
  fortress-pi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBjNCB0PcU37lyDLGjTlPEUeTQJvt4i3BmqgqQ/Zw1YV";
  cooper-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd4gyZtFs9MKhR5YR/o8S+sbcGy1hIi+ObMe79oThhX";
  nix-nuc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQvXc07ECdtcmTwL2uV3pkNPFPoSLbr4s/dcdvRGpDB";
in
{
  "fortress-pi-tunnel.age".publicKeys = [ cooper fortress-pi ];

  # Bearer token for calendar-bridge writes: the Mac checks it, Stubert on nix-nuc sends it.
  "calendar-bridge-token.age".publicKeys = [ cooper cooper-mbp nix-nuc ];
}
