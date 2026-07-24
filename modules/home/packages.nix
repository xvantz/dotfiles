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
    dotnet-sdk_9
    bottom
    cmake
    ripgrep
    gcc
    fd
    gnumake
    unzip
    ghostty
    spotify
    libnotify
    pavucontrol
    playerctl
    grim
    slurp
    satty
    fastfetch
    bitwarden-desktop
    nixd
    alejandra
    telegram-desktop
    pnpm
    xv-codex
    xv-gemini
    tldr
    ouch
    procs
    fzf
    bat
    gammastep
    obsidian
    bun
    vesktop
    xv-pi-coding
    python3
    uv
    imagemagick
    yarn-berry_4
    obs-studio
    yandex-cloud
  ];

  services.udiskie = {
    enable = true;
    tray = "never";
  };
}
