{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    wget
    curl
    wl-clipboard
    xclip
    waybar
    fuzzel
    mako
    xwayland-satellite
    pciutils
    lm_sensors
    mission-center
    mesa-demos
    vulkan-tools
    gsettings-desktop-schemas
    adwaita-icon-theme
    glib
    gtk3
    gtk4
    libadwaita
    hyprlock
    hypridle
    catppuccin-cursors.mochaDark
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
    nix-tree
    easyeffects
    brightnessctl
    sops
    yt-dlp
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    openssl
    # openssl_1_1
    stdenv.cc.cc.lib
    libatomic_ops
    gcc-unwrapped.lib

    zlib
    icu
    krb5
  ];
}
