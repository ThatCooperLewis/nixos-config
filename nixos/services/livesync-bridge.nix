{ lib, pkgs, constants, ... }:

let
  # Pin of https://github.com/vrtmrz/livesync-bridge — bump alongside major
  # updates of the Self-hosted LiveSync plugin on devices.
  src = pkgs.fetchFromGitHub {
    owner = "vrtmrz";
    repo = "livesync-bridge";
    rev = "454f7611e88f681b3430234e03424be28ed3c7be";
    hash = "sha256-EDbowbevqGsjwQEejl/LUmS8JFHAv6H8JBx9IYt3eNY=";
  };

  stateDir = "/var/lib/livesync-bridge";
  vaultDir = constants.obsidian.vaultDir;

  # Template only — ${...} placeholders are filled from secrets.env at start,
  # so credentials never enter the nix store or git.
  configTemplate = pkgs.writeText "livesync-bridge-config.json" (builtins.toJSON {
    peers = [
      {
        type = "couchdb";
        name = "couchdb-nas";
        url = constants.obsidian.couchdbUrl;
        database = "\${LSB_COUCHDB_DATABASE}";
        username = "\${LSB_COUCHDB_USERNAME}";
        password = "\${LSB_COUCHDB_PASSWORD}";
        passphrase = "";
        obfuscatePassphrase = "";
        baseDir = "";
        useRemoteTweaks = true;
      }
      {
        type = "storage";
        name = "local-vault";
        baseDir = "${vaultDir}/";
        scanOfflineChanges = true;
        useChokidar = true;
      }
    ];
  });
in
{
  systemd.tmpfiles.rules = [
    "d ${constants.obsidian.vaultRoot} 0755 cooper users -"
    "d ${vaultDir} 0755 cooper users -"
  ];

  systemd.services.livesync-bridge = {
    description = "Obsidian LiveSync Bridge (CouchDB <-> filesystem)";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.deno pkgs.gettext ];

    # deno.jsonc uses BYONM (nodeModulesDir: manual), so the app needs a
    # writable checkout with node_modules materialized by `deno install`.
    # First start after a pin bump needs network; the deno cache persists.
    preStart = ''
      set -eu
      cd "$STATE_DIRECTORY"
      if [ ! -f app/.src-rev ] || [ "$(cat app/.src-rev)" != "${src}" ]; then
        rm -rf app
        cp -r ${src} app
        chmod -R u+w app
        printf '%s' "${src}" > app/.src-rev
      fi
      cd app && deno install
      umask 077
      envsubst < ${configTemplate} > "$STATE_DIRECTORY/config.json"
    '';

    serviceConfig = {
      Type = "simple";
      User = "cooper";
      Group = "users";
      StateDirectory = "livesync-bridge";
      # No WorkingDirectory: it would apply to preStart too, which is what
      # creates the app dir in the first place. cd in the wrapper instead.
      ExecStart = pkgs.writeShellScript "livesync-bridge-run" ''
        cd ${stateDir}/app
        exec ${pkgs.deno}/bin/deno task run
      '';
      Restart = "always";
      RestartSec = 10;
      Environment = [
        "DENO_DIR=${stateDir}/deno-cache"
        "LSB_CONFIG=${stateDir}/config.json"
        "LSB_HEALTH_FILE=${stateDir}/health"
        "HOME=/home/cooper"
      ];
      # Create by hand, chmod 600 cooper:users, never committed:
      #   LSB_COUCHDB_DATABASE=<from LiveSync plugin settings on any device>
      #   LSB_COUCHDB_USERNAME=<from LiveSync plugin settings>
      #   LSB_COUCHDB_PASSWORD=<plaintext>
      EnvironmentFile = "${stateDir}/secrets.env";
    };
  };

  # Upstream swallows unhandled rejections, so replication can stall without
  # the process exiting; a nightly restart plus scanOfflineChanges self-heals.
  systemd.timers.livesync-bridge-restart = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:30";
      Persistent = true;
    };
  };
  systemd.services.livesync-bridge-restart = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl try-restart livesync-bridge.service";
    };
  };
}
