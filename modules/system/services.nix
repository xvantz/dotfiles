{pkgs-unstable, ...}: {
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  security.pam.services.hyprlock = {};
  services.fstrim.enable = true;
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    servers = [
      "pool.ntp.org"
      "162.159.200.1"
      "162.159.200.123"
      "216.239.35.0"
      "216.239.35.4"
    ];
    extraConfig = "makestep 1.0 -1";
  };

  systemd.user.extraConfig = "DefaultTimeoutStopSec=10s";

  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-cpu;
  };
  services.udisks2.enable = true;
  services.udiskie.enable = true;
}
