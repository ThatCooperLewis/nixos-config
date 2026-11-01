{ ... }:

# SSH alias for the Windows gaming PC (`ssh windows-pc`), which runs the
# built-in OpenSSH Server with PowerShell as its shell. Uses the mDNS name
# because UniFi hands the PC its address by DHCP, with no reservation.
# The PC side (sshd, administrators_authorized_keys) is set up by hand:
# Windows isn't Nix-managed.

{
  programs.ssh.extraConfig = ''
    Host windows-pc
      HostName lewis-pc.local
      User cooper
      IdentityFile /Users/cooper/.ssh/id_ed25519
  '';
}
