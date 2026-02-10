{...}: {
  services.printing.enable = true;
  security.polkit.enable = true;
  programs.light.enable = true;

  services.udev.extraRules = ''
    ACTION=="add|change", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e487", ENV{LIBINPUT_ATTR_KEYBOARD_DEBOUNCE_DELAY}="50ms"
    ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card1", ATTR{device/power_dpm_force_performance_level}="high"
  '';
}
