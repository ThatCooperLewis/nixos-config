{ config, constants, ... }:

##########################
####### InfluxDB2 ########
##########################

/*

Timeseries metrics database for telegraf, on nix-nuc. Org, bucket, users and tokens are provisioned by Nix.
- Data stays in the default /var/lib/influxdb2. Metrics are disposable (about 17 days of retention), so there's no backup.
- Admin login: user "admin", password in secrets/influxdb-admin-password.age (decrypt from the Mac with agenix).
- Telegraf writes with its own write-only token (secrets/influxdb-telegraf-token.age), never the admin one.

*/

let
  org = "lewis-homelab";
  bucket = "influx";
in
{
  age.secrets = {
    influxdb-admin-password = { file = ../secrets/influxdb-admin-password.age; owner = "influxdb2"; };
    influxdb-admin-token = { file = ../secrets/influxdb-admin-token.age; owner = "influxdb2"; };
    influxdb-telegraf-token = { file = ../secrets/influxdb-telegraf-token.age; owner = "influxdb2"; };
  };

  services.influxdb2 = {
    enable = true;
    provision = {
      enable = true;
      initialSetup = {
        username = "admin";
        passwordFile = config.age.secrets.influxdb-admin-password.path;
        tokenFile = config.age.secrets.influxdb-admin-token.path;
        organization = org;
        inherit bucket;
        retention = 1500001; # seconds, about 17 days
      };
      organizations.${org}.auths.telegraf = {
        description = "telegraf: write metrics";
        tokenFile = config.age.secrets.influxdb-telegraf-token.path;
        writeBuckets = [ bucket ];
      };
    };
  };

  # Open to the LAN so other hosts' telegraf can report here
  networking.firewall.allowedTCPPorts = [ constants.ports.influxdb ];
}
