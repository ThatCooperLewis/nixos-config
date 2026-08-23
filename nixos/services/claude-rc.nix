{ lib, pkgs, ... }:

let
  configDir = "/home/cooper/Development/stubert/config";
in
{
  # `claude remote-control` (aka `claude rc`) runs a persistent server that lets
  # Cooper drive local Claude Code sessions from claude.ai/code or the mobile
  # app. It authenticates via ~/.claude and connects outbound to Anthropic, so
  # no inbound firewall port is required.
  systemd.services.claude-rc = {
    description = "Claude Code Remote Control";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = configDir;
      ExecStart = "${pkgs.claude-code}/bin/claude remote-control";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 30;

      # Run as cooper — needs the ~/.claude auth/credentials and home paths.
      User = "cooper";
      Group = "users";

      # Claude CLI (Node.js) needs HOME and a PATH that covers node, git (for
      # worktree spawns), and the general system tools spawned sessions invoke.
      Environment = [
        "HOME=/home/cooper"
        "PATH=${lib.makeBinPath [ pkgs.claude-code pkgs.nodejs pkgs.git ]}:/run/current-system/sw/bin"
      ];
    };
  };
}
