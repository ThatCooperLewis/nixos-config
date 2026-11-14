{ config, pkgs, ... }:

# `switchctl`: headless control of the RealHD PSW24-25G-MG managed switch
# (VLAN membership per port, MAC table, save running config, config backup).
# The switch only serves its web UI; this scripts that UI's JSON CGI API. See
# network-switch.py. Interactive use takes credentials from the environment
# (homelab-claude's .env via bin/withenv), never the Nix store.
#
# network-switch-backup: nightly launchd agent that downloads the startup and
# running configs, keeps a dated copy whenever either changes, logs a warning
# when running differs from startup (changes not yet saved), and mirrors it all
# to the NAS. Login comes from secrets/network-switch-env.age. Runs on the Mac
# because nix-nuc's VLAN can't reach the switch's management IP.

let
  constants = import ../../constants.nix;

  switchctl = pkgs.writeScriptBin "switchctl" ''
    #!${pkgs.python3}/bin/python3 -I
    ${builtins.replaceStrings [ "@defaultHost@" ] [ constants.hosts.networkSwitch ]
      (builtins.readFile ./network-switch.py)}
  '';

  dest = "cooper@${constants.ips.nas}:/mnt/janet/backup-data/homelab/network-switch";
  sshKey = "/Users/cooper/.ssh/id_photobackup";

  backupScript = pkgs.writeShellScript "network-switch-backup" ''
    set -euo pipefail
    echo "== $(date '+%F %T') start"

    set -a; . ${config.age.secrets.network-switch-env.path}; set +a

    state="$HOME/Library/Application Support/network-switch-backup"
    mkdir -p "$state/history"
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

    ${switchctl}/bin/switchctl backup "$tmp"

    # The header's uptime line changes every run; ignore it when comparing.
    norm() { grep -v '^! System Up Time:' "$1"; }
    stamp=$(date '+%F-%H%M')
    for kind in startup running; do
      new="$tmp/$kind-config.cfg"; cur="$state/$kind-config.cfg"
      if [ ! -f "$cur" ] || ! diff -q <(norm "$new") <(norm "$cur") >/dev/null; then
        cp "$new" "$state/history/$kind-$stamp.cfg"
        echo "$kind config changed: saved history/$kind-$stamp.cfg"
      fi
      cp "$new" "$cur"
    done

    if ! diff -q <(norm "$state/startup-config.cfg") <(norm "$state/running-config.cfg") >/dev/null; then
      echo "WARNING: running config differs from startup (unsaved changes, lost on reboot)"
    fi

    # No --delete: the NAS keeps every history file even if pruned here.
    ${pkgs.rsync}/bin/rsync -rt --timeout=120 \
      -e "/usr/bin/ssh -i ${sshKey} -o BatchMode=yes -o IdentitiesOnly=yes" \
      "$state/" "${dest}/"
    echo "== $(date '+%F %T') finished"
  '';
in
{
  environment.systemPackages = [ switchctl ];

  age.secrets.network-switch-env = {
    file = ../../secrets/network-switch-env.age;
    owner = "cooper";
    mode = "0400";
  };

  # launchd runs a missed job when the Mac wakes, so sleep only delays it.
  launchd.user.agents.network-switch-backup.serviceConfig = {
    ProgramArguments = [ "${backupScript}" ];
    StartCalendarInterval = [ { Hour = 3; Minute = 45; } ];
    StandardOutPath = "/Users/cooper/Library/Logs/network-switch-backup.log";
    StandardErrorPath = "/Users/cooper/Library/Logs/network-switch-backup.log";
  };
}
