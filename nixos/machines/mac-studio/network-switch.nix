{ pkgs, ... }:

# `switchctl`: headless control of the RealHD PSW24-25G-MG managed switch
# (VLAN membership per port, MAC table, save running config). The switch only
# serves its web UI; this scripts that UI's JSON CGI API. See network-switch.py.
# Credentials come from the environment (homelab-claude's .env via bin/withenv),
# never the Nix store.

let
  constants = import ../../constants.nix;

  switchctl = pkgs.writeScriptBin "switchctl" ''
    #!${pkgs.python3}/bin/python3 -I
    ${builtins.replaceStrings [ "@defaultHost@" ] [ constants.hosts.networkSwitch ]
      (builtins.readFile ./network-switch.py)}
  '';
in
{
  environment.systemPackages = [ switchctl ];
}
