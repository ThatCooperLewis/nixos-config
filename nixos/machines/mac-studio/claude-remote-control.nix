{ pkgs, ... }:

# Keeps a `claude remote-control` server running on this Mac so Claude Code
# here is always reachable from claude.ai/code and the Claude mobile app.
#
# Two pieces:
#   - claude-remote-control: the server, under launchd KeepAlive, so a crash,
#     exit, logout or reboot brings it straight back.
#   - claude-remote-control-watchdog: every 5 minutes, checks the server's
#     debug log for a recent successful poll/heartbeat to Anthropic. The
#     process often stays alive after its bridge silently gives up (the
#     reconnect budget runs out, or it parks after a failed token refresh;
#     anthropics/claude-code#34255), which KeepAlive alone can't see. When the
#     bridge has been silent for staleMinutes, it restarts the server.
#
# A restart ends sessions that were running on the server; they show as
# offline in the app, and new ones start in workDir.
#
# Logs: ~/Library/Logs/claude-remote-control{,-watchdog}.log (stderr and
# restarts), plus the server's debug log, rotated to .1 on each start.

let
  label = "org.nixos.claude-remote-control";
  workDir = "/Users/cooper/Developer/homelab-claude";
  logDir = "/Users/cooper/Library/Logs";
  debugLog = "${logDir}/claude-remote-control.debug.log";
  staleMinutes = 10;
  maxDebugLogMB = 200;

  server = pkgs.writeShellScript "claude-remote-control" ''
    set -eu
    # Spawned sessions use git, nix, ssh, etc. from the normal profile.
    export PATH=${pkgs.claude-code}/bin:/etc/profiles/per-user/cooper/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
    [ -f ${debugLog} ] && mv -f ${debugLog} ${debugLog}.1
    cd ${workDir}
    echo "$(date '+%F %T') starting claude remote-control" >&2
    exec claude remote-control --name "$(scutil --get LocalHostName)" \
      --debug-file ${debugLog} </dev/null
  '';

  watchdog = pkgs.writeShellScript "claude-remote-control-watchdog" ''
    set -u
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    log() { echo "$(date '+%F %T') $*"; }
    target="gui/$(id -u)/${label}"

    pid=$(launchctl print "$target" 2>/dev/null | awk '$1 == "pid" {print $3}')
    # Not running: KeepAlive restarts it on its own.
    [ -n "$pid" ] && [ -f ${debugLog} ] || exit 0

    now=$(date +%s)
    started=$(stat -f %B ${debugLog})
    reason=""

    last=$(grep -E 'work/poll -> 200|/heartbeat -> 200' ${debugLog} | tail -n 1 | cut -c1-19)
    if [ -n "$last" ]; then
      last_ok=$(date -j -u -f '%Y-%m-%dT%H:%M:%S' "$last" +%s)
    else
      last_ok=$started
    fi
    if (( now - last_ok > ${toString (staleMinutes * 60)} )); then
      reason="no successful poll or heartbeat for $(( (now - last_ok) / 60 ))m"
    elif (( $(stat -f %z ${debugLog}) > ${toString (maxDebugLogMB * 1024 * 1024)} )); then
      reason="debug log over ${toString maxDebugLogMB}MB"
    fi

    [ -n "$reason" ] || exit 0
    log "restarting (pid $pid): $reason"
    launchctl kickstart -k "$target"
  '';
in
{
  launchd.user.agents.claude-remote-control.serviceConfig = {
    Label = label;
    ProgramArguments = [ "${server}" ];
    RunAtLoad = true;
    KeepAlive = true;
    # Back off if it exits right away (e.g. logged out of Claude).
    ThrottleInterval = 60;
    # stdout is the redrawn status screen; errors go to stderr.
    StandardOutPath = "/dev/null";
    StandardErrorPath = "${logDir}/claude-remote-control.log";
  };

  launchd.user.agents.claude-remote-control-watchdog.serviceConfig = {
    ProgramArguments = [ "${watchdog}" ];
    StartInterval = 300;
    ProcessType = "Background";
    StandardOutPath = "${logDir}/claude-remote-control-watchdog.log";
    StandardErrorPath = "${logDir}/claude-remote-control-watchdog.log";
  };
}
