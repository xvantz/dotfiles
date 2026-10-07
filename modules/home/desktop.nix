{pkgs, ...}: {
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {};
  };

  # Idempotent session starter: opens the standard workflow once,
  # never duplicates, never moves existing windows.
  # Wired via spawn-at-startup in config/niri/config.kdl.
  home.packages = [
    (pkgs.writeShellScriptBin "niri-workflow" ''
      for i in $(seq 1 20); do
        ${pkgs.niri}/bin/niri msg -j version >/dev/null 2>&1 && break
        sleep 0.5
      done
      maybe() {
        app="$1"; shift
        ${pkgs.niri}/bin/niri msg -j windows \
          | ${pkgs.jq}/bin/jq -e --arg a "$app" 'any(.[]; .app_id == $a)' >/dev/null \
          || ${pkgs.niri}/bin/niri msg action spawn -- "$@" >/dev/null
      }
      maybe zen-beta "$HOME/.nix-profile/bin/zen-beta"
      sleep 0.3
      maybe org.keepassxc.KeePassXC "$HOME/.nix-profile/bin/keepassxc"
      sleep 0.3
      maybe com.mitchellh.ghostty "$HOME/.nix-profile/bin/ghostty"
      sleep 0.3
      maybe org.telegram.desktop "$HOME/.nix-profile/bin/Telegram"
    '')
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    configPackages = [
      pkgs.niri
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      };
      niri = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      };
    };
  };
}
