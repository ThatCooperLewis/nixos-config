{ pkgs, app, user, constants, ... }:

{
  # imports = [
  #   ../storage/nas-secrets.nix
  # ];

  services.telegraf = {
    enable = true;
    extraConfig = {
      # Host
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
      # Database
      outputs = {
        influxdb_v2 = {
          urls = [ constants.urls.influxdb ];
          # TODO: Get nix secrets going
          token =  "telegraf";
          organization = "lewis-homelab";
          bucket = "influx";
          timeout = "5s";
        };
      };
      # Metrics
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
