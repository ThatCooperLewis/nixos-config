{ pkgs, ... }:

# Decision log: an append-only record of key homelab decisions and changes,
# written by Claude (and Cooper) so future agents can see what was decided,
# when, and exactly what was done.
#
# - `decision`: the CLI (decision-log.py). SQLite + FTS5 database in logDir,
#   plus decisions.md there, a read-only Markdown copy regenerated on every
#   write. Also linked as homelab-claude/bin/decision.
# - Claude Code managed settings (Mac-wide, every session in any folder): two
#   hooks. SessionStart prints the logging rules, recent entries and tag list
#   into each session; Stop blocks once when a session changed state (API
#   writes, rebuilds, edits under ~/Nix, ...) without a `decision add` since.
#   Managed settings because Claude Code never writes that file, unlike
#   ~/.claude/settings.json.
# - homelab-claude/.claude/settings.json: that project's permissions. Claude
#   Code saves approvals to settings.local.json, which stays unmanaged.
# - decision-log-backup: nightly launchd agent that snapshots the database,
#   keeps a dated copy whenever it changed, and mirrors it all to the NAS.
#
# The entries themselves are data, not config: restore them from the NAS copy.

let
  constants = import ../../constants.nix;
  project = "Developer/homelab-claude";
  logDir = "/Users/cooper/${project}/decision-log";

  decision = pkgs.writeScriptBin "decision" ''
    #!${pkgs.python3}/bin/python3 -I
    ${builtins.replaceStrings [ "@logDir@" ] [ logDir ] (builtins.readFile ./decision-log.py)}
  '';

  managedSettings = {
    permissions.allow = [ "Bash(decision *)" ];
    hooks = {
      SessionStart = [ { hooks = [ { type = "command"; command = "${decision}/bin/decision hook session-start"; } ]; } ];
      Stop = [ { hooks = [ { type = "command"; command = "${decision}/bin/decision hook stop"; } ]; } ];
    };
  };
  managedSettingsFile = pkgs.writeText "claude-managed-settings.json" (builtins.toJSON managedSettings);

  projectSettings = {
    permissions = {
      allow = [
        "Bash(bin/envnames)"
        "Bash(./bin/envnames)"
      ];
      deny = [
        "Read(./.env)"
        "Read(./.env.*)"
        "Edit(./.env)"
        "Bash(cat .env*)"
        "Bash(cat ./.env*)"
        "Bash(less .env*)"
        "Bash(head .env*)"
        "Bash(tail .env*)"
        "Bash(grep * .env*)"
        "Bash(env)"
        "Bash(printenv*)"
      ];
    };
  };

  dest = "cooper@${constants.ips.nas}:/mnt/janet/backup-data/homelab/decision-log";
  sshKey = "/Users/cooper/.ssh/id_photobackup";
  sqlite = "${pkgs.sqlite}/bin/sqlite3";

  backupScript = pkgs.writeShellScript "decision-log-backup" ''
    set -euo pipefail
    echo "== $(date '+%F %T') start"
    if [ ! -f "${logDir}/decisions.db" ]; then
      echo "no decision log yet"; exit 0
    fi

    state="$HOME/Library/Application Support/decision-log-backup"
    mkdir -p "$state/history"
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

    # .backup gives a consistent copy even mid-write.
    ${sqlite} "${logDir}/decisions.db" ".backup '$tmp/decisions.db'"
    sum=$(${sqlite} "$tmp/decisions.db" .dump | shasum -a 256 | cut -d' ' -f1)
    if [ "$sum" != "$(cat "$state/last.sha256" 2>/dev/null || true)" ]; then
      cp "$tmp/decisions.db" "$state/history/decisions-$(date '+%F-%H%M').db"
      echo "$sum" > "$state/last.sha256"
      echo "log changed: saved a dated copy"
    fi
    cp "$tmp/decisions.db" "$state/decisions.db"
    cp "${logDir}/decisions.md" "$state/decisions.md" 2>/dev/null || true
    chmod u+w "$state/decisions.md" 2>/dev/null || true

    # No --delete: the NAS keeps every dated copy.
    ${pkgs.rsync}/bin/rsync -rt --timeout=120 \
      -e "/usr/bin/ssh -i ${sshKey} -o BatchMode=yes -o IdentitiesOnly=yes" \
      "$state/" "${dest}/"
    echo "== $(date '+%F %T') finished"
  '';
in
{
  environment.systemPackages = [ decision ];

  # Claude Code reads this path for organization-managed settings; nothing
  # else on this Mac uses it.
  system.activationScripts.postActivation.text = ''
    install -d -m 0755 "/Library/Application Support/ClaudeCode"
    install -m 0644 ${managedSettingsFile} "/Library/Application Support/ClaudeCode/managed-settings.json"
  '';

  home-manager.users.cooper.home.file = {
    "${project}/.claude/settings.json" = {
      text = builtins.toJSON projectSettings;
      # Replaces the hand-made file the first time; its rules are above.
      force = true;
    };
    "${project}/bin/decision".source = "${decision}/bin/decision";
  };

  launchd.user.agents.decision-log-backup.serviceConfig = {
    ProgramArguments = [ "${backupScript}" ];
    StartCalendarInterval = [ { Hour = 3; Minute = 55; } ];
    StandardOutPath = "/Users/cooper/Library/Logs/decision-log-backup.log";
    StandardErrorPath = "/Users/cooper/Library/Logs/decision-log-backup.log";
  };
}
