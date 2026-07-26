{...}: {
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      GUI = {
        ShowTrayIcon = true;
        MinimizeOnClose = true;
        MinimizeToTray = true;
      };

      Browser = {
        Enabled = true;
      };

      SSHAgent = {
        Enabled = true;
        UseOpenSSH = true;
      };

      FdoSecrets = {
        Enabled = true;
      };

      Security = {
        LockDatabaseScreenLock = true;
        LockDatabaseIdleSeconds = 600;
        ClearClipboardTimeout = 10;
      };


      PasswordGenerator = {
        Length = 25;
      };

      General = {
        AutoReloadOnChange = true;
        BackupBeforeSave = true;
      };
    };
  };

  xdg.autostart.enable = true;
}
