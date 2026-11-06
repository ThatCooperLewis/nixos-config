{ config, lib, constants, ...}:


#####################
####### CADDY #######
#####################

/*

Reverse proxy for *.local.lewisho.me (LAN IPs) and *.tail.lewisho.me (Tailscale IPs), with TLS from Let's Encrypt
via the Cloudflare DNS challenge. Runs the caddy-cloudflare image because NixOS's Caddy can't easily load that plugin.
Runs on nix-nuc; it used to run on caddy-pi.

*/

let
  docker = constants.docker;
in
{
  imports = [
    ./container-base.nix
    ../storage/nas-secrets.nix
  ];

  users = {
    users.caddy = {
      isSystemUser = true;
      uid = constants.users.caddy;
      group = "caddy";
      description = "Caddy-Cloudflare User";
      extraGroups = [ "wheel" ];
    };
    groups.caddy.gid = constants.users.caddy;
  };

  # Make sure the caddy data config is properly set
  system.activationScripts.ensureCaddyDataDir = lib.mkAfter ''
    mkdir -p /etc/caddy/data
    chown -R caddy:caddy /etc/caddy/data
  '';

  # Copy the Caddy env file (Cloudflare DNS token) from the NAS before Caddy starts, on every boot and deploy.
  # If the NAS is unreachable, keep the last copy so Caddy still comes up.
  systemd.services.caddy-env = {
    description = "Copy the Caddy env file from the NAS";
    wantedBy = [ "multi-user.target" ];
    before = [ "docker-caddy.service" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "60s";
    };
    script = ''
      mkdir -p /etc/caddy
      if cp /mnt/nas-secrets/caddy/caddy.env /etc/caddy/caddy.env.new; then
        mv /etc/caddy/caddy.env.new /etc/caddy/caddy.env
      else
        rm -f /etc/caddy/caddy.env.new
        echo "NAS env file unavailable, keeping the existing copy" >&2
      fi
      chown caddy:caddy /etc/caddy/caddy.env
      chmod 0600 /etc/caddy/caddy.env
    '';
  };
  systemd.services.docker-caddy = {
    wants = [ "caddy-env.service" ];
    after = [ "caddy-env.service" ];
    # The Caddyfile is bind-mounted, so restart Caddy whenever it changes
    restartTriggers = [ config.environment.etc."caddy/Caddyfile".text ];
  };

  environment.etc."caddy/Caddyfile" = {
    text = ''



      # Caddy restarts whenever this file changes.
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

      scrutiny.tail.lewisho.me {
        reverse_proxy ${constants.tails.nas}:${toString constants.ports.scrutiny}
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

      tautulli.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.tautulli}
        import cloudflare
      }

      bazarr.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.bazarr}
        import cloudflare
      }

      lidarr.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.lidarr}
        import cloudflare
      }

      prowlarr.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.prowlarr}
        import cloudflare
      }

      tdarr.tail.lewisho.me {
        reverse_proxy ${constants.tails.nuc}:${toString constants.ports.tdarrWeb}
        import cloudflare
      }

      ha.tail.lewisho.me {
        reverse_proxy ${constants.tails.homeAss}:${toString constants.ports.homeAss}
        import cloudflare
      }

      jet.tail.lewisho.me {
        reverse_proxy ${constants.tails.jetkvm}
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
      requestrr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.requestrr}
        import cloudflare
      }
      tdarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.tdarrWeb}
        import cloudflare
      }
      lidarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.lidarr}
        import cloudflare
      }

      bazarr.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.bazarr}
        import cloudflare
      }

      tautulli.local.lewisho.me {
        reverse_proxy ${constants.ips.nuc}:${toString constants.ports.tautulli}
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
      ha.local.lewisho.me {
        reverse_proxy ${constants.urls.homeAss}
        import cloudflare
      }
      jet.local.lewisho.me {
        reverse_proxy ${constants.ips.jetkvm}
        import cloudflare
      }

    '';
    mode = "0644";
    user = "caddy";
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [ constants.ports.http constants.ports.https ];
  networking.firewall.allowedUDPPorts = [ constants.ports.https ];

  virtualisation.oci-containers.containers = {
    caddy = {
      image = "ghcr.io/caddybuilds/caddy-cloudflare:latest";
      ports = docker.ports.caddy;
      user = docker.users.caddy;
      environmentFiles = ["/etc/caddy/caddy.env"]; # Pass the secret API Token
      volumes = [ 
        "${docker.dirs.caddy}/data:/data"
        "${docker.dirs.caddy}/Caddyfile:/etc/caddy/Caddyfile"
      ];
    };
  };
}