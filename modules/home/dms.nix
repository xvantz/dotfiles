{
  pkgs,
  inputs,
  config,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
in {
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.niri.homeModules.niri
  ];

  xdg.configFile."niri/dms/binds.kdl".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/niri/config.kdl";

  programs.dank-material-shell = {
    enable = true;

    dgop.package = inputs.dgop.packages.${pkgs.system}.default;

    niri = {
      enableKeybinds = false;
      enableSpawn = true;

      includes = {
        enable = true;
        originalFileName = "my-custom-config";
        filesToInclude = ["binds"];
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
            {
              id = "systemTray";
              enabled = true;
            }
            {
              id = "keyboard_layout_name";
              enabled = true;
            }
            {
              id = "network_speed_monitor";
              enabled = true;
            }
            {
              id = "notificationButton";
              enabled = true;
            }
          ];
          centerWidgets = ["music" "clock" "weather"];
          rightWidgets = [
            {
              id = "clipboard";
              enabled = true;
            }
            {
              id = "memUsage";
              enabled = true;
            }
            {
              id = "cpuUsage";
              enabled = true;
            }
            {
              id = "cpuTemp";
              enabled = true;
              minimumWidth = true;
            }
            {
              id = "battery";
              enabled = true;
            }
            {
              id = "controlCenterButton";
              enabled = true;
            }
          ];
        }
      ];
    };
  };
}
