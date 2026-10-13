{ pkgs, ... }:

# Day/night model swap for LM Studio. Keeps exactly one LLM loaded: the fast
# model by day (07:55-01:55) and the heavy model overnight (01:55-07:55), so
# the heavy model never holds RAM while the Mac is used for photo editing.
# Stubert's Helper Agent uses `model: auto`, so it follows whatever is loaded.
# Swaps run 5 minutes early so the half-hourly pebble-ingest cron doesn't land
# mid-load.

let
  fast = "qwen/qwen3.6-35b-a3b";
  heavy = "qwen3.5-122b-a10b";
  contextLength = 65536;
  lms = "/Users/cooper/.lmstudio/bin/lms";
  logFile = "/Users/cooper/Library/Logs/lmstudio-model-schedule.log";

  swapScript = pkgs.writeShellScript "lmstudio-model-schedule" ''
    set -euo pipefail
    export PATH=${pkgs.jq}/bin:/usr/bin:/bin

    log() { echo "$(date '+%F %T') $*"; }

    # lms load prints a progress bar; keep only the result line.
    load() {
      ${lms} load "$1" --context-length ${toString contextLength} -y 2>&1 \
        | tr '\r' '\n' | grep -i 'loaded successfully\|error' | tail -n 1
    }

    # Pick by clock, matching the 01:55/07:55 launchd schedule below.
    now=$((10#$(date +%H) * 60 + 10#$(date +%M)))
    if (( now >= 115 && now < 475 )); then want=${heavy}; else want=${fast}; fi

    if ! ${lms} ls --json | jq -e --arg k "$want" 'any(.[]; .modelKey == $k)' >/dev/null; then
      log "$want is not downloaded; using ${fast}"
      want=${fast}
    fi

    loaded=$(${lms} ps --json | jq -r '.[] | .modelKey // .identifier')
    if [ "$loaded" = "$want" ]; then
      log "$want already loaded"
      exit 0
    fi

    log "swapping [''${loaded//$'\n'/, }] -> $want"
    ${lms} unload --all
    if load "$want"; then
      log "loaded $want"
    elif [ "$want" != ${fast} ]; then
      log "failed to load $want; falling back to ${fast}"
      load ${fast}
    else
      log "failed to load ${fast}"
      exit 1
    fi
  '';
in
{
  # Also runs at login, and launchd runs a missed swap when the Mac wakes.
  launchd.user.agents.lmstudio-model-schedule.serviceConfig = {
    ProgramArguments = [ "${swapScript}" ];
    StartCalendarInterval = [
      { Hour = 1; Minute = 55; }
      { Hour = 7; Minute = 55; }
    ];
    RunAtLoad = true;
    StandardOutPath = logFile;
    StandardErrorPath = logFile;
  };
}
