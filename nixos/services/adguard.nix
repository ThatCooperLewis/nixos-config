{ pkgs, app, lib, user, constants, ... }:

#############################
####### AdGuard Home ########
#############################

/*

https://wiki.nixos.org/wiki/Adguard_Home
https://search.nixos.org/options?query=services.adguardhome
https://github.com/AdguardTeam/AdGuardHome

*/

{
  networking.firewall.allowedTCPPorts = [ constants.ports.dns ];
  networking.firewall.allowedUDPPorts = [ constants.ports.dns ];

  services.adguardhome = {
    enable = true;
    port = 3003;
    openFirewall = true;
    settings = {
      http = {
        address = "0.0.0.0:3003";
      };
      http_proxy = "";
      dns = {
        bind_hosts = [
          "0.0.0.0"
        ];
        upstream_dns = [
          "1.1.1.1"
          "1.0.0.1"

        ];
      };

      users = [
        {
          name = "lewis-homelab";
          password = "$2b$12$RIXZ9Nqcy5m4gC92fhjpYOycSV5dkWfU49iMSl.NZdl0y2NFi1DN6";
        }
      ];

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;

        parental_enabled = false;
        safebrowsing_enabled = false;
        safe_search.enabled = false;
      };
      # The following notation uses map
      # to not have to manually create {enabled = true; url = "";} for every filter
      # This is, however, fully optional
      filters = map(url: { enabled = true; url = url; }) [
        # "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"  # The Big List of Hacked Malware Web Sites (Apparently this one is too heavy-handed)
        # "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt"  # malicious url blocklist
        # "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt"  # Peter Lowe's Blocklist
        "https://raw.githubusercontent.com/ph00lt0/blocklist/master/blocklist.txt" # https://github.com/ph00lt0/blocklist
      ];

      user_rules = [
        # Twitter news links
        "@@||t.co^$important"

        # TikTok
        "@@||tiktokcdn-us.com^$important"
        
        # Oregonian
        "@@||www.oregonlive.com^$important" 
        "@@||embeddedassistant.googleapis.com^$important"
        
        # Instagram
        "@@||graph.facebook.com^$important"

        # Apple HomeKit
        "@@||init.ess.apple.com^$important"
        "@@||smp-device-content.apple.com^$important"
      ];
    };
  };
}