{
  pkgs,
  config,
  selfPath,
  ...
}: {
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  programs.hyprlock.enable = true;

  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "${selfPath}/config/hypr/hyprlock.conf";
  xdg.configFile."hypr/mocha.conf".source = config.lib.file.mkOutOfStoreSymlink "${selfPath}/config/hypr/mocha.conf";
  xdg.configFile."hypr/nix-black.png".source = config.lib.file.mkOutOfStoreSymlink "${selfPath}/config/hypr/nix-black.png";
  xdg.configFile."hypr/logo.png".source = config.lib.file.mkOutOfStoreSymlink "${selfPath}/config/hypr/logo.png";

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session && ${pkgs.playerctl}/bin/playerctl pause";
        after_sleep_cmd = "niri msg action power-on-monitors";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1000;
          on-timeout = "niri msg action power-off-monitors";
          on-resume = "niri msg action power-on-monitors";
        }
      ];
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    configPackages = [
      pkgs.niri
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
      };
      niri = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
      };
    };
  };
}
