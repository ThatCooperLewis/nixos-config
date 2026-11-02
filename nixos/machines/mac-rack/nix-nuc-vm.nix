{ pkgs, ... }:

# Keeps the nix-nuc VM (UTM, see machines/nix-nuc) running: at login and every
# 2 minutes, starts it if it's stopped and resumes it if it's suspended. Runs in
# the GUI session because utmctl drives the UTM app, which needs auto-login.
#
# For maintenance, `touch ~/.nix-nuc-vm-hold` pauses this, so a stopped VM stays
# stopped; remove the file to resume.

let
  vm = "nix-nuc";
  utmctl = "/Applications/UTM.app/Contents/MacOS/utmctl";
  hold = "/Users/cooper/.nix-nuc-vm-hold";
  logFile = "/Users/cooper/Library/Logs/nix-nuc-vm.log";

  ensureRunning = pkgs.writeShellScript "nix-nuc-vm" ''
    set -u
    export PATH=/usr/bin:/bin

    log() { echo "$(date '+%F %T') $*"; }

    [ -e ${hold} ] && exit 0

    state=$(${utmctl} status ${vm} 2>&1)
    case "$state" in
      started|starting|resuming) exit 0 ;;
      stopped|paused|suspended)
        log "$state, starting"
        ${utmctl} start ${vm} 2>&1 | while read -r line; do log "$line"; done
        ;;
      *) log "unexpected status: $state" ;;
    esac
  '';
in
{
  launchd.user.agents.nix-nuc-vm.serviceConfig = {
    ProgramArguments = [ "${ensureRunning}" ];
    StartInterval = 120;
    RunAtLoad = true;
    StandardOutPath = logFile;
    StandardErrorPath = logFile;
  };
}
