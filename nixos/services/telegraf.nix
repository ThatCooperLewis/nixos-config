{ config, constants, ... }:

##########################
######## Telegraf ########
##########################

/*

Host metrics, sent to InfluxDB on nix-nuc (services/influxdb.nix).
The write token reaches telegraf as a systemd credential, read through telegraf's systemd secret store,
so it never lands in the Nix store or the environment. A host that imports this needs to be a recipient
of secrets/influxdb-telegraf-token.age in secrets/secrets.nix.

*/

{
  age.secrets.telegraf-influx-token.file = ../secrets/influxdb-telegraf-token.age;

  # The systemd secret store looks up "@{systemd:influx_token}" as the credential "telegraf.influx_token"
  systemd.services.telegraf.serviceConfig.LoadCredential = [
    "telegraf.influx_token:${config.age.secrets.telegraf-influx-token.path}"
  ];

  services.telegraf = {
    enable = true;
    extraConfig = {
      agent = {
        interval = "10s";
        round_interval = true;
        metric_batch_size = 1000;
        metric_buffer_limit = 10000;
        collection_jitter = "0s";
        flush_interval = "10s";
        flush_jitter = "0s";
        precision = "";
        omit_hostname = false;
      };
      secretstores.systemd = [ { id = "systemd"; } ];
      outputs.influxdb_v2 = {
        urls = [ constants.urls.influxdb ];
        token = "@{systemd:influx_token}";
        organization = "lewis-homelab";
        bucket = "influx";
        timeout = "5s";
      };
      inputs = {
        cpu = {
          percpu = true;
          totalcpu = true;
          collect_cpu_time = false;
          report_active = false;
        };
        diskio = { };
        disk = { };
        kernel = { };
        mem = { };
        swap = { };
        system = { };
        net = { };
        temp = {
          name_override = "temp_cpu";
        };
      };
    };
  };
}
