{ lib, ... }:

# nix-nuc keeps all of its state on a second virtual disk (ext4, label nuc-data), so the VM
# can move hosts, even architectures: attach this disk to a fresh OS disk built from the
# flake and boot. The OS disk only holds what Nix can rebuild. Inventory: Brain Wiki/Mac Rack.
let
  data = "/data";
  bind = src: {
    device = "${data}/${src}";
    fsType = "none";
    options = [ "bind" "x-systemd.requires-mounts-for=${data}" ];
  };
in
{
  # Mounted in the initrd: agenix reads the SSH host key from here during activation
  fileSystems.${data} = {
    device = "/dev/disk/by-label/nuc-data";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/home/cooper/Homelab" = bind "home/Homelab";            # Arr stack configs and databases
  fileSystems."/home/cooper/Development" = bind "home/Development";    # Stubert and other repos
  fileSystems."/home/cooper/.claude" = bind "home/.claude";
  fileSystems."/home/cooper/.ssh" = bind "home/.ssh";
  fileSystems."/var/www/geocities-portfolio" = bind "www/geocities-portfolio";
  fileSystems."/var/lib/livesync-bridge" = bind "var/livesync-bridge";
  fileSystems."/var/lib/tailscale" = bind "var/tailscale";              # keeps node nix-nuc-1 and its IP
  fileSystems."/mnt/obsidian" = bind "obsidian";

  # Stubert's build output is per-architecture, so it stays on the OS disk
  fileSystems."/home/cooper/Development/stubert/target" = {
    device = "/var/cache/stubert-target";
    fsType = "none";
    options = [ "bind" "x-systemd.requires-mounts-for=/home/cooper/Development" ];
  };
  systemd.tmpfiles.rules = [ "d /var/cache/stubert-target 0755 cooper users -" ];

  # Same host keys on any host, so agenix and every client's known_hosts keep working
  services.openssh.hostKeys = [
    { path = "${data}/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
    { path = "${data}/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
  ];

  nix.settings.secret-key-files = lib.mkForce [ "${data}/nix-signing/key.sec" ];

  # ~/.claude.json is one file Claude replaces atomically, which a file bind mount can't
  # take. CLAUDE_CONFIG_DIR keeps it inside ~/.claude instead.
  environment.sessionVariables.CLAUDE_CONFIG_DIR = "/home/cooper/.claude";
  systemd.services.stubert.environment.CLAUDE_CONFIG_DIR = "/home/cooper/.claude";
}
