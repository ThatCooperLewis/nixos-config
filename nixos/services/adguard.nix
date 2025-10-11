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
        # Social Media
        "@@||t.co^$important"
        "@@||tiktokcdn-us.com^$important"
        "@@||www.tiktok.com^$important"
        "@@||www.facebook.com^$important"
        "@@||graph.facebook.com^$important"
        
        # Oregonian
        "@@||www.oregonlive.com^$important" 
        "@@||embeddedassistant.googleapis.com^$important"

        # Rando news source
        "@@||www.sltrib.com^$important"

        # Apple HomeKit
        "@@||init.ess.apple.com^$important"
        "@@||smp-device-content.apple.com^$important"
        "@@||smp-device-content.apple.com^$important"
        "@@||api.smoot.apple.com^$important"
        "@@||query.ess.apple.com^$important"
        "@@||lcdn-locator.apple.com^$important"
        "@@||xp.apple.com^$important"
        "@@||www.sltrib.com^$important"
        "@@||sentry.io^$important"
        "@@||o64374.ingest.sentry.io^$important"
        "@@||xp.itunes-apple.com.akadns.net^$important"
        "@@||us-east-1.prod.service.minerva.devices.a2z.com^$important"
        # Specific to HomePod
        "@@||identity.ess.apple.com^$client='10.40.69.100'"
        "@@||lcdn-locator.apple.com^$client='10.40.69.100'"
        "@@||ocsp.comodoca.com^$client='10.40.69.100'"

        # Amazon Orders
        "@@||com_amazon_amazon.triggers-v1.prod.mobile.weblab.a2z.com^$important"
        "@@||aax-us-east-retail-direct.amazon.com^$important"
        "@@||unagi-na.amazon.com^$important"
        "@@||fls-na.amazon.com^$important"
        "@@||unagi.amazon.com^$important"
        "@@||pancake.apple.com^$important"
        "@@||aes.us-east.ono.axp.amazon-adsystem.com^$important"
        "@@||maps.hereapi.com^$important"

        # Princess Polly Store
        "@@||trk.princesspolly.com^$important"
        "@@||link.citycast.fm^$important"

        # Nuuly (Probably not all required)
        # Ari's iPad
        "@@||fast.fonts.net^$client='10.40.69.11'"
        "@@||script.crazyegg.com^$client='10.40.69.11'"
        "@@||bam.nr-data.net^$client='10.40.69.11'"
        "@@||auth.split.io^$client='10.40.69.11'"
        "@@||js.datadome.co^$client='10.40.69.11'"
        "@@||sdk.split.io^$client='10.40.69.11'"
        "@@||api-js.datadome.co^$client='10.40.69.11'"
        "@@||js-agent.newrelic.com^$client='10.40.69.11'"

        # Nuuly - Ari's iPhone
        "@@||fast.fonts.net^$client='10.40.69.10'"
        "@@||script.crazyegg.com^$client='10.40.69.10'"
        "@@||bam.nr-data.net^$client='10.40.69.10'"
        "@@||auth.split.io^$client='10.40.69.10'"
        "@@||js.datadome.co^$client='10.40.69.10'"
        "@@||sdk.split.io^$client='10.40.69.10'"
        "@@||api-js.datadome.co^$client='10.40.69.10'"
        "@@||js-agent.newrelic.com^$client='10.40.69.10'"

        # Package tracking
        "@@||www.yuntrack.com^$important"
        "@@||www.yunexpress.com^$important"

        # Sony TV App Access
        "@@||androidtvchannels-pa.googleapis.com^$client='10.40.69.110'"
        "@@||app-measurement.com^$client='10.40.69.110'"
        "@@||firebase-settings.crashlytics.com^$client='10.40.69.110'"
        "@@||***REMOVED***^$client='10.40.69.110'"
        "@@||firebaselogging-pa.googleapis.com^$client='10.40.69.110'"
        "@@||api-partner.spotify.com^$client='10.40.69.110'"
      ];
    };
  };
}
