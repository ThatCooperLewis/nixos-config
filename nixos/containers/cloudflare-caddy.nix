{ config, lib, constants, ...}:


################################
####### CLOUDFLARE-CADDY #######
################################

/*

The built-in NixOS Caddy service doesn't handle its cloudflare DNS plugin easily.
Instead of messing with the fully-functional internal caddy on the NUC, my solution is to run a separate caddy service on a Pi.
This secondary proxy is dedicated to handling Tailscale traffic sent through Cloudflare. 

*/

let
  docker = constants.docker;
in
{

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

  environment.etc."caddy/Caddyfile" = {
    text = ''
      (cloudflare) {
        tls {
            dns cloudflare {$CLOUDFLARE_DNS_TOKEN}
        }
      }

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

    '';
    mode = "0644";
    user = "caddy";
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [ constants.ports.caddypi constants.ports.caddypiSSH ];
  virtualisation.oci-containers.containers = {
    caddy = {
      image = "ghcr.io/caddybuilds/caddy-cloudflare:latest";
      ports = docker.ports.caddypi;
      user = docker.users.caddypi;
      environmentFiles = ["/var/lib/cloudflared/dns.env"]; # Pass the secret API Token
      environment = {
      	PUID = docker.users.caddypi;
      	PGID = docker.users.caddypi;
      };
      volumes = [ 
        "${docker.dirs.caddypi}/data:/data"
        "${docker.dirs.caddypi}/Caddyfile:/etc/caddy/Caddyfile"
      ];
    };
  };
}