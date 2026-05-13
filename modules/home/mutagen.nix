{pkgs, ...}: {
  home.packages = with pkgs; [
    mutagen
  ];

  systemd.user.services.mutagen-daemon = {
    Unit.Description = "Mutagen Terminal Daemon";
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mutagen}/bin/mutagen daemon run";
      Restart = "always";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.mutagen-cocos-sync = {
    Unit = {
      Description = "Mutagen Sync for Cocos Project";
      Requires = ["mutagen-daemon.service"];
      After = ["mutagen-daemon.service" "network.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "start-cocos-sync" ''
        sleep 2

        ${pkgs.mutagen}/bin/mutagen sync terminate cocos-dev >/dev/null 2>&1 || true

        ${pkgs.mutagen}/bin/mutagen sync create \
          --name=cocos-dev \
          -m two-way-resolved \
          --ignore="node_modules,.git,library,local,temp" \
          --stage-mode-beta=neighboring \
          --watch-mode-beta=force-poll \
          --watch-polling-interval-beta=1 \
          /home/xvantz/projects/cocos \
          xvantz@192.168.122.157:C:/Users/xvantz/projects/cocos-projects

        exec ${pkgs.coreutils}/bin/tail -f /dev/null
      '';
      ExecStop = "${pkgs.mutagen}/bin/mutagen sync terminate cocos-dev";
      Restart = "always";
      RestartSec = "30s";
    };
    Install.WantedBy = ["default.target"];
  };
}
