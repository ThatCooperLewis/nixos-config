{ pkgs, ... }:

# Nightly rsync of the photo DAS volumes to TrueNAS (janet/photography-backup).
# ZFS snapshots on the NAS hold older versions, so `--delete` mirrors are safe.
# Ingest also goes to Time Machine hourly; this copy is for easy browsing.

let
  constants = import ../../constants.nix;

  dest = "cooper@${constants.ips.nas}:/mnt/janet/photography-backup";
  sshKey = "/Users/cooper/.ssh/id_photobackup";

  backupScript = pkgs.writeShellScript "photo-backup" ''
    set -uo pipefail
    volume="$1"
    target="$2"
    src="/Volumes/$volume"

    echo "== $(date '+%F %T') $volume -> $target"

    # Only run against a mounted volume. An empty leftover /Volumes folder
    # would otherwise make --delete wipe the backup.
    if ! /sbin/mount | grep -q " on $src (" ; then
      echo "$src is not mounted, skipping"
      exit 0
    fi

    # -rlt, not -a: the NAS keeps its own permissions (files owned by other
    # users can't be chmod'ed by cooper, which would fail every run).
    ${pkgs.rsync}/bin/rsync -rlt --delete --max-delete=2000 \
      --info=stats2 \
      --exclude .DS_Store --exclude .Spotlight-V100 --exclude .fseventsd \
      --exclude .Trashes --exclude .TemporaryItems --exclude .DocumentRevisions-V100 \
      --exclude .bzvol \
      -e "/usr/bin/ssh -i ${sshKey} -o BatchMode=yes -o IdentitiesOnly=yes" \
      "$src/" "${dest}/$target/"
    status=$?
    echo "== $(date '+%F %T') finished, exit $status"
    exit $status
  '';

  mkJob = volume: target: hour: minute: {
    serviceConfig = {
      ProgramArguments = [ "${backupScript}" volume target ];
      StartCalendarInterval = [ { Hour = hour; Minute = minute; } ];
      StandardOutPath = "/Users/cooper/Library/Logs/photo-backup-${target}.log";
      StandardErrorPath = "/Users/cooper/Library/Logs/photo-backup-${target}.log";
      LowPriorityIO = true;
    };
  };
in
{
  # launchd runs a missed job when the Mac wakes, so sleep only delays it.
  launchd.user.agents.photo-backup-ingest = mkJob "Ingest" "ingest" 1 0;
  launchd.user.agents.photo-backup-library = mkJob "Library" "library" 2 30;
}
