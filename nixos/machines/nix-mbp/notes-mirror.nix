{ pkgs, ... }:

# Mirrors the Obsidian vault into an "Obsidian" folder in iCloud Notes every
# 10 minutes, so Siri and Spotlight can search the notes and Kanban boards on
# every Apple device. One-way: the vault is the source, read from nix-nuc's
# LiveSync copy so it's current even when Obsidian isn't open on the Mac.
# Source and details: ./notes-mirror.swift.
#
# It drives Notes through AppleScript, so the first run asks "notes-mirror
# wants to control Notes": click OK. A changed binary (new cdhash) asks again.
# Log: ~/Library/Logs/notes-mirror.log (one line per run that changed something).

let
  constants = import ../../constants.nix;

  infoPlist = pkgs.writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key><string>org.nixos.notes-mirror</string>
      <key>CFBundleName</key><string>notes-mirror</string>
      <key>NSAppleEventsUsageDescription</key>
      <string>Copies your Obsidian notes into an Obsidian folder in Notes.</string>
    </dict>
    </plist>
  '';

  notesMirror = pkgs.swiftPackages.stdenv.mkDerivation {
    pname = "notes-mirror";
    version = "1";
    src = ./notes-mirror.swift;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.swift pkgs.darwin.sigtool ];
    buildPhase = ''
      swiftc -O -o notes-mirror $src \
        -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ${infoPlist}
    '';
    # Sign last: fixup's strip would re-sign without the identifier.
    dontFixup = true;
    installPhase = ''
      install -Dm755 notes-mirror $out/bin/notes-mirror
      codesign -f -s - -i org.nixos.notes-mirror $out/bin/notes-mirror
    '';
  };
in
{
  launchd.user.agents.notes-mirror.serviceConfig = {
    ProgramArguments = [
      "${notesMirror}/bin/notes-mirror"
      "${pkgs.rsync}/bin/rsync"
      "${pkgs.cmark-gfm}/bin/cmark-gfm"
      "cooper@${constants.ips.nuc}:/mnt/obsidian/Brain/"
      "/Users/cooper/.ssh/id_nixSSH"
    ];
    RunAtLoad = true;
    StartInterval = 600;
    ProcessType = "Background";
    LowPriorityIO = true;
    StandardOutPath = "/Users/cooper/Library/Logs/notes-mirror.log";
    StandardErrorPath = "/Users/cooper/Library/Logs/notes-mirror.log";
  };
}
