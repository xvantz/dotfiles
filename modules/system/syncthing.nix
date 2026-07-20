{pkgs, ...}: let
  vaultDir = "/home/xvantz/Documents/Passwords";
in {
  services.syncthing = {
    enable = true;
    user = "xvantz";
    dataDir = "/home/xvantz";
    configDir = "/home/xvantz/.config/syncthing";
    guiAddress = "127.0.0.1:8384";

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        "phone" = {id = "QC7W4EP-7365CQF-H67AI7E-7COWDJQ-PG53C6Z-FEOGHB2-ULSUUEY-CRZKRQC";};
      };

      folders = {
        "passwords" = {
          path = vaultDir;
          devices = ["phone"];
          type = "sendreceive";
          rescanInterval = 30;
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "31536000";
              versionsPath = "/home/xvantz/.local/share/syncthing-versions";
            };
          };
        };
      };
    };
  };

  systemd.user.services.keepass-git-sync = {
    enable = true;
    description = "Commit and push Password vault changes to Forgejo";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = vaultDir;
      ExecStart = "${pkgs.writeShellScript "keepass-git-sync" ''
        set -e
        cd "${vaultDir}"
        ${pkgs.git}/bin/git add -A
        ${pkgs.git}/bin/git diff-index --quiet HEAD || (
          ${pkgs.git}/bin/git commit -m "auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
          ${pkgs.git}/bin/git push origin main || true
        )
      ''}";
    };
  };

  systemd.user.paths.keepass-git-watch = {
    enable = true;
    description = "Watch Password vault for changes";
    wantedBy = ["default.target"];
    pathConfig = {
      PathChanged = vaultDir;
      Unit = "keepass-git-sync.service";
    };
  };
}
