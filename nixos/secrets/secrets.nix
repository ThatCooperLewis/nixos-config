# agenix recipients: which public keys can decrypt each secret. Not imported by any machine.
# Edit a secret:  cd ~/Nix/nixos/secrets && nix run github:ryantm/agenix -- -e <name>.age
# After changing keys here (e.g. a reinstalled host has a new host key):  nix run github:ryantm/agenix -- -r
let
  # Cooper's ~/.ssh/id_ed25519, so secrets can always be edited from the Mac
  cooper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9dBYcueY75DBHGBW10FlYz7alzlPznCkJKe6/aPiJw";

  # Host keys: /etc/ssh/ssh_host_ed25519_key.pub on each machine
  fortress-pi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBjNCB0PcU37lyDLGjTlPEUeTQJvt4i3BmqgqQ/Zw1YV";
  # The TrueNAS VM that replaces the Pi (2026-11). Drop the Pi's key above once the Pi is retired
  fortress-vm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFssksh84tW+qdwhMcmvjxVjruAqxGxTZ5UX4dVX/4g";
  mac-studio = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd4gyZtFs9MKhR5YR/o8S+sbcGy1hIi+ObMe79oThhX";
  nix-nuc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQvXc07ECdtcmTwL2uV3pkNPFPoSLbr4s/dcdvRGpDB";
in
{
  "fortress-pi-tunnel.age".publicKeys = [ cooper fortress-pi fortress-vm ];

  # cooper's sudo password on fortress-pi: the hash for the machine, the plaintext for Cooper only
  "fortress-pi-cooper-hash.age".publicKeys = [ cooper fortress-vm ];
  "fortress-pi-cooper-password.age".publicKeys = [ cooper ];

  # Bearer token for calendar-bridge writes: the Mac checks it, Stubert on nix-nuc sends it.
  "calendar-bridge-token.age".publicKeys = [ cooper mac-studio nix-nuc ];
}
