{pkgs-unstable, ...}: {
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  security.pam.services.hyprlock = {};
  services.fstrim.enable = true;
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    servers = ["pool.ntp.org"];
    extraConfig = "makestep 1.0 -1";
  };

  systemd.user.extraConfig = "DefaultTimeoutStopSec=10s";

  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-cpu;
  };
}
