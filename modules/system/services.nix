{...}: {
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  security.pam.services.hyprlock = {};
  services.fstrim.enable = true;
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    servers = ["pool.ntp.org"];
  };

  systemd.user.extraConfig = "DefaultTimeoutStopSec=10s";
}
