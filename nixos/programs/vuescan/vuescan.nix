{ pkgs, ... }:
let
  vuescan = pkgs.callPackage ./pkg.nix { };
in {
    services.udev.packages = [ vuescan ]; # important for vuescan to be able to identify scanners
    environment.systemPackages = [ 
      vuescan 
      pkgs.gtk3
    ];
}