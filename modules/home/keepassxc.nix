{...}: {
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      Browser = {
        Enabled = true;
      };

      SSHAgent = {
        Enabled = true;
      };

      FdoSecrets = {
        Enabled = true;
      };
    };
  };
}
