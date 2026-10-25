{pkgs, ...}: {
  home.packages = with pkgs; [
    usbutils
    lazygit
    lazysql
    go
    golangci-lint
    zig
    nodejs
    eza
    zoxide
    bottom
    cmake
    ripgrep
    gcc
    fd
    gnumake
    unzip
    spotify
    libnotify
    pavucontrol
    playerctl
    grim
    slurp
    satty
    fastfetch
    nixd
    alejandra
    telegram-desktop
    pnpm
    tldr
    ouch
    procs
    fzf
    bat
    gammastep
    obsidian
    bun
    vesktop
    python3
    uv
    imagemagick
    yarn-berry_4
    obs-studio
    yandex-cloud
    claude-code
    ffmpeg
  ];

  services.udiskie = {
    enable = true;
    tray = "never";
  };
}
