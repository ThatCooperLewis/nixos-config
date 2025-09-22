{ lib, constants, ... }:

###############################
###### Porfolio Webhost #######
###############################

/*

Using Nginx to host my portfolio.
To expose via Cloudflare:
Dashboard > Access > Networks > Tunnels > Select & Edit Tunnel > Published Application Rules > Add
*/
let
  dataDir = constants.nuc.dirs.geocitiesPortfolio;
in
{

  #### 1) Create a shared group and let nginx read the site ####
  users.groups.webcontent = { };                       # group for web files
  users.users.nginx.extraGroups = [ "webcontent" ];    # nginx can read via group

  #### 2) Create directories with correct ownership & perms ####
  # - /var/www is world-traversable (standard)
  # - site dir is owned by cooper, group webcontent, and has setgid (2)
  #   so new files inherit the webcontent group.
  systemd.tmpfiles.rules = [
    "d /var/www 0755 root root -"
    "d ${dataDir} 02750 cooper webcontent -"
  ];

  networking.firewall.allowedTCPPorts = [ constants.ports.geocitiesPortfolio ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    virtualHosts."geocities-portfolio" = {
      default = true;  
      enableACME = false;
      forceSSL = false;
      root = dataDir;
      listen = [
        { addr = "0.0.0.0"; port = constants.ports.geocitiesPortfolio; }
      ];

      # extraConfig = ''
      #   # Don't cache HTML at Cloudflare or browsers
      #   location ~* \.(?:html)$ {
      #     add_header Cache-Control "no-cache, no-store, must-revalidate";
      #     add_header Pragma "no-cache";
      #     add_header Expires 0;
      #   }
      # '';
    };
  };
}

