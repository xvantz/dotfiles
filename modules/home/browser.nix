{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [pkgs.keepassxc];
    policies = {
      DisableTelemetry = true;
      ExtensionSettings = {
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
        "keepassxc-browser@keepassxc.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
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
