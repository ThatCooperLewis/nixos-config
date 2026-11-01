{ pkgs, ... }:

# Presence-based model swap for LM Studio. Keeps exactly one LLM loaded: the
# light model while Cooper is using the Mac, and the heavy model once he's
# been away for 20 minutes (no keyboard/mouse input, or screen locked that
# long). 02:00-08:00 is always heavy. Stubert's Helper Agent uses
# `model: auto`, so it follows whatever is loaded.
#
# Checks every minute, but never swaps while a model is generating, has queued
# requests, or served a request in the last few minutes, so ongoing sessions
# finish first. Swaps also skip the 3 minutes before :00 and :30 so the
# half-hourly pebble-ingest cron doesn't land mid-load; the overnight window
# starts at 01:55 for the same reason.

let
  # Keep in sync with the heavy/light labels in stats.nix.
  light = "qwen/qwen3.6-35b-a3b";
  heavy = "qwen3.5-122b-a10b";
  contextLength = 65536;
  awaySeconds = 20 * 60;
  recentUseSeconds = 3 * 60;
  lms = "/Users/cooper/.lmstudio/bin/lms";
  logFile = "/Users/cooper/Library/Logs/lmstudio-model-schedule.log";

  swapScript = pkgs.writeShellScript "lmstudio-model-schedule" ''
    set -euo pipefail
    export PATH=${pkgs.jq}/bin:/usr/sbin:/usr/bin:/bin

    log() { echo "$(date '+%F %T') $*"; }

    # lms load prints a progress bar; keep only the result line.
    load() {
      ${lms} load "$1" --context-length ${toString contextLength} -y 2>&1 \
        | tr '\r' '\n' | grep -i 'loaded successfully\|error' | tail -n 1
    }

    epoch=$(date +%s)
    hm=$((10#$(date +%H) * 60 + 10#$(date +%M)))

    # Seconds since the last keyboard/mouse input.
    idle=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ && !v {v = $NF} END {print int(v / 1e9)}')

    # Seconds the screen has been locked (0 when unlocked).
    session=$(ioreg -n Root -d1 -a)
    locked=0
    if [ "$(plutil -extract IOConsoleUsers.0.CGSSessionScreenIsLocked raw -o - - <<<"$session" 2>/dev/null)" = true ]; then
      locked_at=$(plutil -extract IOConsoleUsers.0.CGSSessionScreenLockedTime raw -o - - <<<"$session" 2>/dev/null || echo "$epoch")
      locked=$((epoch - locked_at))
      (( locked > 0 )) || locked=1
    fi

    if (( hm >= 115 && hm < 480 )); then
      want=${heavy}; why="overnight"
    elif (( idle >= ${toString awaySeconds} || locked >= ${toString awaySeconds} )); then
      want=${heavy}; why="away (idle ''${idle}s, locked ''${locked}s)"
    elif (( locked == 0 )); then
      want=${light}; why="in use"
    else
      exit 0 # locked under 20 minutes: keep whatever is loaded
    fi

    if [ "$want" = ${heavy} ] \
      && ! ${lms} ls --json | jq -e --arg k ${heavy} 'any(.[]; .modelKey == $k)' >/dev/null; then
      want=${light}
    fi

    ps=$(${lms} ps --json)
    loaded=$(jq -r '.[] | .modelKey // .identifier' <<<"$ps")
    if [ "$loaded" = "$want" ]; then exit 0; fi

    # Let ongoing sessions finish: wait until nothing is generating, queued,
    # or used recently.
    if jq -e --argjson now "$epoch" '
        any(.[]; (.status // "idle") != "idle" or (.queued // 0) > 0
                 or ($now * 1000 - (.lastUsedTime // 0)) < ${toString (recentUseSeconds * 1000)})
      ' <<<"$ps" >/dev/null; then
      exit 0
    fi
    if (( hm % 30 >= 27 )); then exit 0; fi

    log "$why: swapping [''${loaded//$'\n'/, }] -> $want"
    ${lms} unload --all
    if load "$want"; then
      log "loaded $want"
    elif [ "$want" != ${light} ]; then
      log "failed to load $want; falling back to ${light}"
      load ${light}
    else
      log "failed to load ${light}"
      exit 1
    fi
  '';
in
{
  launchd.user.agents.lmstudio-model-schedule.serviceConfig = {
    ProgramArguments = [ "${swapScript}" ];
    StartInterval = 60;
    RunAtLoad = true;
    StandardOutPath = logFile;
    StandardErrorPath = logFile;
  };
}
