{pkgs, ...}: {
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];

  # services.displayManager.sddm = {
  #   enable = true;
  #   wayland.enable = true;
  #   theme = "catppuccin-mocha-mauve";
  # };

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
      mesa
      libglvnd
    ];
  };

  environment.variables = {
    "WLR_DRM_DEVICES" = "/dev/dri/card1";
    "WLR_RENDERER_ALLOW_SOFTWARE" = "0";
  };
}
