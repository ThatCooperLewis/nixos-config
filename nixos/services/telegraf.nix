{ pkgs, app, user, constants, ... }:

{
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
        influxdb = {
          urls = [ constants.urls.influxdb ];
          database = "influx";
          timeout = "10s";
          username = "telegraf";
          password = "metricsmetricsmetricsmetrics";
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
