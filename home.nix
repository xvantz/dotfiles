{ config, pkgs, pkgs-unstable, zen-browser-pkg, inputs, ... }:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.niri.homeModules.niri
  ];
  home.username = "xvantz";
  home.homeDirectory = "/home/xvantz";

  home.stateVersion = "25.11"; 

  home.packages = with pkgs; [
    usbutils
    yazi
	  lazygit
	  starship
	  go
	  zig
	  nodejs
	  rustup
	  eza
	  zoxide
	  dotnet-sdk_8
	  tree-sitter
	  neohtop
    cmake
    ripgrep
    gcc
    fd
    gnumake
    tmux
    unzip
    ghostty
    zen-browser-pkg
    waybar
    docker
    nbfc-linux
    spotify
    libnotify
    pulseaudio
    pavucontrol
    playerctl
    grim slurp swappy
    fastfetch
    bitwarden-desktop
    pkgs-unstable.telegram-desktop
  ];

  programs.home-manager.enable = true;

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/nvim";

  programs.dank-material-shell = {
    enable = true;
    
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;

    niri = {
      enableKeybinds = false;
      enableSpawn = true;
      
      includes = {
        enable = true;
        originalFileName = "my-custom-config";
        filesToInclude = [ "binds" ];
      };
    };

    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableClipboardPaste = true;
    enableAudioWavelength = true;

    systemd.enable = false;

    settings = {
    currentThemeName = "default";
    currentThemeCategory = "generic";
    matugenScheme = "scheme-tonal-spot";
    runUserMatugenTemplates = true;
    
    use24HourClock = true;
    fontFamily = "JetBrains Mono Nerd Font";
    monoFontFamily = "JetBrains Mono Nerd Font";
    cornerRadius = 12;
    
    showWeather = true;
    showMusic = true;
    showClipboard = true;
    showCpuUsage = true;
    showMemUsage = true;
    showBattery = true;
    
    notificationOverlayEnabled = true;
    notificationCompactMode = true;
    notificationPopupPosition = 2;
    notificationTimeoutNormal = 5000;

    matugenTemplateNeovim = false;
    matugenTemplateGhostty = false;

    barConfigs = [
      {
        id = "default";
        name = "Main Bar";
        enabled = true;
        leftWidgets = [
          { id = "systemTray"; enabled = true; }
          { id = "keyboard_layout_name"; enabled = true; }
          { id = "network_speed_monitor"; enabled = true; }
          { id = "notificationButton"; enabled = true; }
        ];
        centerWidgets = [ "music" "clock" "weather" ];
        rightWidgets = [
          { id = "clipboard"; enabled = true; }
          { id = "memUsage"; enabled = true; }
          { id = "cpuUsage"; enabled = true; }
          { id = "cpuTemp"; enabled = true; minimumWidth = true; }
          { id = "battery"; enabled = true; }
          { id = "controlCenterButton"; enabled = true; }
        ];
      }
    ];
  };
  };

  xdg.configFile."niri/dms/binds.kdl".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/niri/config.kdl";

  programs.zsh = {
	  enable = true;
	  # autoSuggestions.enable = true;
	  syntaxHighlighting.enable = true;
	  shellAliases = {
	    ls = "eza --icons";
	    cd = "z";
      rebuild = "sudo nixos-rebuild switch --flake ~/.dotfiles#nixos";
	  };
	  initContent = ''
	    eval "$(starship init zsh)"
	    eval "$(zoxide init zsh)"
	  '';
  };
  programs.zoxide.enableZshIntegration = true;

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      theme = "Catppuccin Mocha";
      font-size = 12;
      window-decoration = false;
      confirm-close-surface = false;
    };
  };

  home.sessionVariables = {
    XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = "24";
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "catppuccin-mocha-dark-cursors";
    };
  };

  programs.hyprlock.enable = true;

  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/hypr/hyprlock.conf";
  xdg.configFile."hypr/mocha.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/hypr/mocha.conf";
  xdg.configFile."hypr/nix-black.png".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/hypr/nix-black.png";
  xdg.configFile."hypr/logo.png".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/hypr/logo.png";

  programs.anyrun = {
    enable = true;
    config = {
      x = { fraction = 0.5; };
      y = { fraction = 0.3; };
      width = { fraction = 0.3; };
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = null;

      plugins = [
        "${pkgs.anyrun}/lib/libapplications.so"
        "${pkgs.anyrun}/lib/librink.so"
        "${pkgs.anyrun}/lib/libshell.so"
        "${pkgs.anyrun}/lib/libtranslate.so"
      ];
    };

    extraCss = ''
      .some_class {
        background: red;
      }
    '';
  };

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
}
