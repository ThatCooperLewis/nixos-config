{ config, pkgs, ... }:

# HTTP/JSON bridge to Apple Calendar and Reminders (EventKit), for Stubert's
# apple-calendar skill on nix-nuc. Reads, creates and edits; never deletes.
# Source and API: ./calendar-bridge.swift.
#
# It runs as a launchd agent in the GUI session because macOS only grants
# Calendar/Reminders access (TCC) to a process it can prompt for. On first
# start, and again whenever the binary changes (new cdhash), click Allow on
# both prompts. Check with: curl -s localhost:8485/health
#
# Only nix-nuc (LAN + Tailscale) and localhost get answers. Writes also need
# the bearer token in secrets/calendar-bridge-token.age (agenix, decrypted
# with this Mac's SSH host key); nix-nuc gets the same secret for Stubert.

let
  constants = import ../../constants.nix;
  port = constants.ports.calendarBridge;
  stripScheme = url: builtins.replaceStrings [ "http://" "https://" ] [ "" "" ] url;

  allowed = [
    "127.0.0.1"
    "::1"
    constants.ips.nuc
    (stripScheme constants.tails.nuc)
  ];

  # Embedded in the binary: TCC needs the usage strings and a stable identifier.
  infoPlist = pkgs.writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key><string>org.nixos.calendar-bridge</string>
      <key>CFBundleName</key><string>calendar-bridge</string>
      <key>NSCalendarsFullAccessUsageDescription</key>
      <string>Lets Stubert read and edit your calendar events.</string>
      <key>NSRemindersFullAccessUsageDescription</key>
      <string>Lets Stubert read and edit your reminders.</string>
    </dict>
    </plist>
  '';

  calendarBridge = pkgs.swiftPackages.stdenv.mkDerivation {
    pname = "calendar-bridge";
    version = "1";
    src = ./calendar-bridge.swift;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.swift pkgs.darwin.sigtool ];
    buildPhase = ''
      swiftc -O -o calendar-bridge $src \
        -framework EventKit -framework Network \
        -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ${infoPlist}
    '';
    # Sign last: fixup's strip would re-sign without the identifier.
    dontFixup = true;
    installPhase = ''
      install -Dm755 calendar-bridge $out/bin/calendar-bridge
      codesign -f -s - -i org.nixos.calendar-bridge $out/bin/calendar-bridge
    '';
  };
in
{
  environment.systemPackages = [ calendarBridge ];

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.calendar-bridge-token = {
    file = ../../secrets/calendar-bridge-token.age;
    owner = "cooper";
    mode = "0400";
  };

  launchd.user.agents.calendar-bridge.serviceConfig = {
    ProgramArguments = [
      "${calendarBridge}/bin/calendar-bridge"
      (toString port)
      config.age.secrets.calendar-bridge-token.path
    ] ++ allowed;
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Background";
    StandardOutPath = "/Users/cooper/Library/Logs/calendar-bridge.log";
    StandardErrorPath = "/Users/cooper/Library/Logs/calendar-bridge.log";
  };
}
