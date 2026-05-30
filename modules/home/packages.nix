{
  pkgs,
  customPkgs,
  ...
}: {
  home.packages = with pkgs; [
    usbutils
    lazygit
    lazysql
    go
    golangci-lint
    zig
    nodejs
    rustup
    eza
    zoxide
    dotnet-sdk_9
    neohtop
    cmake
    ripgrep
    gcc
    fd
    gnumake
    unzip
    ghostty
    waybar
    nbfc-linux
    spotify
    libnotify
    pulseaudio
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
    customPkgs.codex
    customPkgs.gemini
    tldr
    ouch
    procs
    fzf
    bat
    gammastep
    obsidian
    discord
    bun
    vesktop
    zoom-us
    customPkgs.pi-coding
    python3
    uv
    imagemagick
  ];

  services.udiskie = {
    enable = true;
    tray = "never";
  };
}
