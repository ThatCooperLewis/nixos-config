{ config, user, constants, ... }:

{
    users = {
        users.tailscale = {
            isSystemUser = true;
            uid = constants.users.tailscale;
            group = "tailscale";
            description = "Tailscale VPN";
            extraGroups = [ "wheel" ];
        };
        groups.tailscale.gid = constants.users.tailscale;
    };

    networking.firewall.allowedTCPPorts = [ constants.ports.tailscale ];

    services.tailscale = {
        enable = true;
        port = constants.ports.tailscale;
    };
}