{...}: {
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  security.pam.services.hyprlock = {};
  services.fstrim.enable = true;

  systemd.user.extraConfig = "DefaultTimeoutStopSec=10s";
}
