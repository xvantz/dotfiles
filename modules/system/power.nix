{...}: {
  services.thermald.enable = true;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  services.upower.enable = true;
  programs.coolercontrol.enable = true;
  services.power-profiles-daemon.enable = false;
}
