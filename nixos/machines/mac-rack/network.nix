{ ... }:

# Wired on the Homelab VLAN (switch port MGE13, untagged VLAN 50) through the
# ACASIS 10GbE NIC. The address itself (10.50.0.3/24, router 10.50.0.1, matching
# constants.ips.macRack) is set by hand in System Settings: nix-darwin has no
# option for interface addresses. DNS is managed here.
{
  networking.knownNetworkServices = [ "Thunderbolt Ethernet Slot 1" ];
  networking.dns = [ "1.1.1.1" "1.0.0.1" ];
}
