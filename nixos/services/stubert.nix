{ lib, pkgs, constants, ... }:

let
  repoDir = "/home/cooper/Development/stubert";
  configDir = "${repoDir}/config";
  binary = "${repoDir}/target/release/stubert";
in
{
  # Make stubert CLI available in all shells
  environment.shellInit = ''
    export PATH="${repoDir}/target/release:$PATH"
  '';

  networking.firewall.allowedTCPPorts = [ constants.ports.stubert ];

  systemd.services.stubert = {
    description = "Stubert";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${binary} run --runtime-dir ${configDir}";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 30;

      # Run as cooper — needs access to ~/.claude auth and home dir paths
      User = "cooper";
      Group = "users";

      # Claude CLI (Node.js) needs HOME and PATH
      Environment = [
        "HOME=/home/cooper"
        "PATH=${repoDir}/target/release:${lib.makeBinPath [ pkgs.claude-code pkgs.nodejs ]}:/run/current-system/sw/bin"
      ];

      # Load bot tokens and secrets
      EnvironmentFile = "${configDir}/.env";
    };
  };
}
