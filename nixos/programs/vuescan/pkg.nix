{ lib, stdenv, fetchurl, gnutar, autoPatchelfHook, glibc, gtk2, gtk3, libxkbcommon, xorg, libgudev
, makeDesktopItem }:

/*
Vuescan isn't allowed to be packaged officially
https://github.com/NixOS/nixpkgs/issues/217996
*/

let
  pname = "vuescan";
  version = "9.7";
  desktopItem = makeDesktopItem {
    name = "VueScan";
    desktopName = "VueScan";
    genericName = "Scanning Program";
    comment = "Scanning Program";
    icon = "vuescan";
    terminal = false;
    type = "Application";
    startupNotify = true;
    categories = [ "Graphics" "Utility" ];
    keywords = [ "scan" "scanner" ];

    exec = "vuescan";
  };
in stdenv.mkDerivation rec {
  name = "${pname}-${version}";

   src = fetchurl {
     url = "https://www.hamrick.com/files/vuex6497.tgz";
     hash = "sha256-v8gByN7sXjO5l+xo/uogSzFlTL8rQrEx+1n37uGjGmA=";
   };

  # Stripping breaks the program
  dontStrip = true;

  nativeBuildInputs = [ gnutar autoPatchelfHook ];

  buildInputs = [ 
    glibc 
    gtk2 
    gtk3
    libxkbcommon
    xorg.libSM 
    libgudev 
  ];

  unpackPhase = ''
    tar xfz $src
  '';

  installPhase = ''
    install -m755 -D VueScan/vuescan $out/bin/vuescan

    mkdir -p $out/share/icons/hicolor/scalable/apps/
    cp VueScan/vuescan.svg $out/share/icons/hicolor/scalable/apps/vuescan.svg 

    mkdir -p $out/lib/udev/rules.d/
    cp VueScan/vuescan.rul $out/lib/udev/rules.d/60-vuescan.rules

    mkdir -p $out/share/applications/
    ln -s ${desktopItem}/share/applications/* $out/share/applications
  '';
}