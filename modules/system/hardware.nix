{...}: {
  services.printing.enable = true;
  security.polkit.enable = true;
  programs.light.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card1", ATTR{device/power_dpm_force_performance_level}="high"
  '';
  environment.etc."libinput/local-overrides.quirks".text = ''
    [RK Keyboard Filter]
    MatchUdevType=keyboard
    MatchVendorGroup=0x342d
    AttrDebounceDelay=40
  '';
}
