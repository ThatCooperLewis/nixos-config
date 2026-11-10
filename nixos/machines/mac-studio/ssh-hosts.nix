{ ... }:

# SSH aliases for homelab hosts, written to /etc/ssh/ssh_config.
# ~/.ssh/config is read first and wins, so don't define these hosts there too.

let
  constants = import ../../constants.nix;
in
{
  programs.ssh.extraConfig = ''
    Host nix-nuc
      HostName ${constants.ips.nuc}
      User cooper
      IdentityFile /Users/cooper/.ssh/id_nixSSH
      IdentitiesOnly yes

    # HAOS "Terminal & SSH" add-on (core_ssh): a container with /config, /ssl
    # and the `ha` CLI. Key-only; the key is set in the add-on's options.
    Host homeassistant
      HostName ${constants.ips.homeAss}
      User root
      IdentityFile /Users/cooper/.ssh/id_ed25519
      IdentitiesOnly yes
  '';
}
