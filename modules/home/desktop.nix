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
      # Wait until all four are actually open (slow starters steal focus),
      # then put ghostty on top.
      for i in $(seq 1 60); do
        have_all=1
        for app in zen-beta org.keepassxc.KeePassXC com.mitchellh.ghostty org.telegram.desktop; do
          ${pkgs.niri}/bin/niri msg -j windows \
            | ${pkgs.jq}/bin/jq -e --arg a "$app" 'any(.[]; .app_id == $a)' >/dev/null \
            || have_all=0
        done
        [ "$have_all" -eq 1 ] && break
        sleep 1
      done
      gid=$(${pkgs.niri}/bin/niri msg -j windows \
        | ${pkgs.jq}/bin/jq -r '[.[] | select(.app_id == "com.mitchellh.ghostty")] | last | .id // empty')
      if [ -n "$gid" ]; then
        ${pkgs.niri}/bin/niri msg action focus-window --id "$gid"
      fi
      # Deterministic column order on workspace code, left to right:
      # ghostty, zen-beta, keepassxc. move-column-left is a no-op at the edge.
      for app in org.keepassxc.KeePassXC zen-beta com.mitchellh.ghostty; do
        wid=$(${pkgs.niri}/bin/niri msg -j windows \
          | ${pkgs.jq}/bin/jq -r --arg a "$app" '[.[] | select(.app_id == $a)] | last | .id // empty')
        if [ -n "$wid" ]; then
          ${pkgs.niri}/bin/niri msg action focus-window --id "$wid"
          ${pkgs.niri}/bin/niri msg action move-column-left
          ${pkgs.niri}/bin/niri msg action move-column-left
          ${pkgs.niri}/bin/niri msg action move-column-left
        fi
      done
      if [ -n "$gid" ]; then
        ${pkgs.niri}/bin/niri msg action focus-window --id "$gid"
      fi
      # Zen restores its own half-width on cold start, ignoring the open
      # rule. Re-apply maximize once it has settled (toggle is conditional
      # on the actual tile width, so a correct state is never flipped).
      zwid=$(${pkgs.niri}/bin/niri msg -j windows \
        | ${pkgs.jq}/bin/jq -r '[.[] | select(.app_id == "zen-beta")] | last | .id // empty')
      if [ -n "$zwid" ]; then
        wwidth=$(${pkgs.niri}/bin/niri msg -j windows \
          | ${pkgs.jq}/bin/jq -r --argjson id "$zwid" '[.[] | select(.id == $id)] | .[0].layout.tile_size[0] // 0')
        if [ "$((${wwidth%.*} + 0))" -lt 1500 ]; then
          ${pkgs.niri}/bin/niri msg action focus-window --id "$zwid"
          ${pkgs.niri}/bin/niri msg action maximize-window-to-edges
          ${pkgs.niri}/bin/niri msg action focus-window --id "$gid"
        fi
      fi
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
