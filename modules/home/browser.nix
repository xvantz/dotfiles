{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      ExtensionSettings = {
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4664623/bitwarden_password_manager-2025.12.1.xpi";
          installation_mode = "force_installed";
        };
        "vimium-c@gdh1995.cn" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
          installation_mode = "force_installed";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
        "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi";
        };
      };
      Preferences = {
        "browser.tabs.unloadOnLowMemory" = {
          Value = true;
          Status = "locked";
        };
        "browser.low_mem_strategy_aggressive" = {
          Value = true;
          Status = "locked";
        };
        "dom.ipc.processCount" = {
          Value = 4;
          Status = "locked";
        };
        "browser.sessionstore.restore_on_demand" = {
          Value = true;
          Status = "locked";
        };
        "browser.sessionstore.restore_tabs_lazily" = {
          Value = true;
          Status = "locked";
        };
        "browser.tabs.min_inactive_duration_before_unload" = {
          Value = 1200000;
          Status = "locked";
        };
      };
    };
  };
}
