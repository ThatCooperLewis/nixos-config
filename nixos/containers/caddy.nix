{ config, lib, constants, ...}:


#####################
####### CADDY #######
#####################

/*

The built-in NixOS Caddy service doesn't handle its cloudflare DNS plugin easily.
Instead of messing with the fully-functional internal caddy on the NUC, my solution is to run a separate caddy service on a Pi.
This secondary proxy is dedicated to handling Tailscale traffic sent through Cloudflare. 

*/

let
  docker = constants.docker;
in
{
  imports = [
    ../storage/nas-secrets.nix
  ];

  users = {
    users.caddy = {
      isSystemUser = true;
      uid = constants.users.caddypi;
      group = "caddy";
      description = "Caddy-Cloudflare User";
      extraGroups = [ "wheel" ];
    };
    groups.caddy.gid = constants.users.caddypi;
  };

  # Make sure the caddy data config is properly set
  system.activationScripts.ensureCaddyDataDir = lib.mkAfter ''
    mkdir -p /etc/caddy/data
    chown -R caddy:caddy /etc/caddy/data
  '';

  # Copy the Caddy env file from NAS
  system.activationScripts.populateCaddyEnv = lib.mkAfter ''
      mkdir -p /etc/caddy
      cp /mnt/nas-secrets/caddy/caddy.env /etc/caddy/caddy.env
      chown -R caddy:caddy /etc/caddy
  '';

  # Changes to Caddyfile will now autmoatically update
  system.activationScripts.restartCaddy = ''
    /run/current-system/sw/bin/systemctl restart docker-caddy
  '';

  environment.etc."caddy/Caddyfile" = {
    text = ''



      ##### !!!WARNING!!! #####
      # This service is set to restart anytime the machine runs nixos-rebuild!
      # Anything configured here should be for local admin only.



      (cloudflare) {
        tls {
            dns cloudflare {$CLOUDFLARE_DNS_TOKEN}
        }
      }

      ## Tailscale

      nas.tail.lewisho.me {
        reverse_proxy ${constants.tails.nas}
        import cloudflare
      }

      plex.tail.lewisho.me {
        reverse_proxy ${constants.tails.nas}:${toString constants.ports.plex}
        import cloudflare
      }

      sab.tail.lewisho.me {
        reverse_proxy ${constants.tails.nas}:${toString constants.ports.sab}
        import cloudflare
      }

      radarr.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.radarr}
        import cloudflare
      }

      radarr4k.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.radarr4k}
        import cloudflare
      }

      sonarr.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.sonarr}
        import cloudflare
      }

      sonarr4k.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.sonarr4k}
        import cloudflare
      }

      ha.tail.lewisho.me {
        reverse_proxy ${constants.tails.ha}
        import cloudflare
      }

      ## Local

      sonarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.sonarr}
        import cloudflare
      }

      sonarr4k.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.sonarr4k}
        import cloudflare
      }
      radarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.radarr}
        import cloudflare
      }
      radarr4k.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.radarr4k}
        import cloudflare
      }
      prowlarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.prowlarr}
        import cloudflare
      }
      overseerr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.overseerr}
        import cloudflare
      }
      requestrr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.requestrr}
        import cloudflare
      }
      tdarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.tdarrWeb}
        import cloudflare
      }
      tautulli.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.tautulli}
        import cloudflare
      }
      octoprint.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.octoprint}
        import cloudflare
      }
      nas.local.lewisho.me {
        reverse_proxy ${constants.ips.nas}
        import cloudflare
      }
      plex.local.lewisho.me {
        reverse_proxy ${constants.ips.nas}:${toString constants.ports.plex}
        import cloudflare
      }
      sab.local.lewisho.me {
        reverse_proxy ${constants.ips.nas}:${toString constants.ports.sab}
        import cloudflare
      }
      scrutiny.local.lewisho.me {
        reverse_proxy ${constants.ips.nas}:${toString constants.ports.scrutiny}
        import cloudflare
      }
      wifi.local.lewisho.me {
        reverse_proxy ${constants.ips.brain}:${toString constants.ports.omada} {
          transport http {
            tls_insecure_skip_verify
          }
        }
        import cloudflare
      }
      ha.local.lewisho.me {
        reverse_proxy ${constants.urls.ha}
        import cloudflare
      }

    '';
    mode = "0644";
    user = "caddy";
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [ constants.ports.caddypi constants.ports.caddypiSSH ];
  networking.firewall.allowedUDPPorts = [ constants.ports.caddypiSSH ];

  virtualisation.oci-containers.containers = {
    caddy = {
      image = "ghcr.io/caddybuilds/caddy-cloudflare:latest";
      ports = docker.ports.caddypi;
      user = docker.users.caddypi;
      environmentFiles = ["/etc/caddy/caddy.env"]; # Pass the secret API Token
      volumes = [ 
        "${docker.dirs.caddypi}/data:/data"
        "${docker.dirs.caddypi}/Caddyfile:/etc/caddy/Caddyfile"
      ];
    };
  };
}