{pkgs, config, ...}: {
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  security.pam.services.hyprlock = {};
  services.fstrim.enable = true;
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    servers = [
      "pool.ntp.org"
      "162.159.200.1"
      "162.159.200.123"
      "216.239.35.0"
      "216.239.35.4"
    ];
    extraConfig = "makestep 1.0 -1";
  };

  systemd.user.settings = {
    Manager.DefaultTimeoutStopSec = "10s";
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cpu;

    environmentVariables = {
      OLLAMA_HOST = "0.0.0.0:11434";
    };
  };
  services.udisks2.enable = true;

  services.tailscale = {
    enable = true;
    extraUpFlags = ["--accept-dns=false"];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      LidSwitchIgnoreInhibit = "no";
    };
  };
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };
  services.pm = {
    enable = true;
    user = "xvantz";
    dataDir = "/home/xvantz/Documents/pm";
    environmentFile = config.sops.secrets.pm_env.path;
    backup = {
      enable = true;
      repoUrl = "https://git.827482.xyz/xvantz/pm-data.git";
      tokenFile = config.sops.secrets.pm_backup_token.path;
    };
  };

  sops.secrets.pm_env = {
    owner = config.services.pm.user;
    restartUnits = [ "pm-serve.service" ];
  };

  sops.secrets.pm_backup_token = {
    owner = config.services.pm.user;
    restartUnits = [ "pm-serve.service" ];
  };
}
