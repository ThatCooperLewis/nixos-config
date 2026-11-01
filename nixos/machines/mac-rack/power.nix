{ ... }:

# Headless server: never sleep, come back on its own after a hang. Restart after
# power failure isn't set: MacBooks don't support it (systemsetup refuses), and
# the battery rides out short outages anyway.
{
  power.sleep = {
    computer = "never";
    harddisk = "never";
    display = 10;
  };
  power.restartAfterFreeze = true;

  networking.wakeOnLan.enable = true;
}
