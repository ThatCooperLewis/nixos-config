
# Structure from this thread
# https://www.reddit.com/r/NixOS/comments/14dlvbr/sddm_theme/

{ lib
, qtbase
, qtsvg
, qtgraphicaleffects
, qtquickcontrols2
, wrapQtAppsHook
, stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation
rec {
  pname = "catppuccin-frappe";
  version = "1..0";
  dontBuild = true;
  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "sddm";
    rev = "f3db13cbe8e99a4ee7379a4e766bc8a4c2c6c3dd";
    sha256 = "sha256-0zoJOTFjQq3gm5i3xCRbyk781kB7BqcWWNrrIkWf2Xk=";
  };
  nativeBuildInputs = [
    wrapQtAppsHook
  ];

  propagatedUserEnvPkgs = [
    qtbase
    qtsvg
    qtgraphicaleffects
    qtquickcontrols2
  ];


  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src/src/catppuccin-frappe $out/share/sddm/themes/catppuccin-frappe
  '';

}