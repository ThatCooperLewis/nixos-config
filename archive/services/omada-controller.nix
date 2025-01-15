{ config, pkgs, ... }:

let
  omadaPackage = pkgs.stdenv.mkDerivation {
    name = "omada-sdn-controller";
    src = builtins.fetchurl {
      url = "https://static.tp-link.com/upload/software/2024/202412/20241224/Omada_SDN_Controller_v5.15.6.7_linux_x64.tar.gz";
      sha256 = "sha256-of-the-omada-archive"; # Replace with the actual hash
    };
    phases = [ "installPhase" ];
    installPhase = "
      tar zxvf $src -C $out
      $out/Omada_SDN_Controller_v5.15.6.7_linux_x64/install.sh
    ";
  };
in {

  environment.systemPackages = with pkgs; [
    jdk11_headless
    mongodb
    # omadaPackage
  ];

  # Define a systemd service for Omada
  # systemd.services.omada = {
  #   description = "Omada SDN Controller";
  #   after = [ "network.target" "mongodb.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = "${omadaPackage}/bin/controller.sh";
  #     Restart = "always";
  #     User = "omada";
  #     Group = "omada";
  #   };
  # };
}