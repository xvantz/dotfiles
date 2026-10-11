{pkgs, ...}: {
  users.users.containers = {
    isSystemUser = true;
    uid = 1001;
    group = "containers";
    home = "/var/lib/containers";
    createHome = true;
    linger = true;
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
    shell = "${pkgs.shadow}/bin/nologin";
  };

  users.groups.containers = {};

  systemd.services.podman-socket-wait = {
    wantedBy = ["multi-user.target"];
    before = ["hermes-agent.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do [ -S /run/user/1001/podman/podman.sock ] && exit 0; sleep 1; done; echo \"podman socket not ready after 30s\" >&2; exit 1'";
    };
  };

  systemd.user.services.podman-system-service = {
    wantedBy = ["default.target"];
    unitConfig.ConditionUser = "containers";
    serviceConfig = {
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      Restart = "always";
      ExecStartPost = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do [ -S /run/user/1001/podman/podman.sock ] && break; sleep 1; done; chmod 666 /run/user/1001/podman/podman.sock'";
    };
  };

  # The socket is (re)created 0600 by `podman system service`, and the
  # ExecStartPost chmod only runs on service start — a restart or a
  # `Restart=always` bounce leaves it at 0600. A path unit does not help:
  # systemd watches the socket inode, and podman recreates it with unlink+
  # create, which drops the watch. Poll instead: PID-free, immune to
  # inode churn, self-healing after any restart.
  # Needed because the agent container runs as uid 1000 while the socket
  # belongs to uid 1001 (containers).
  systemd.services.podman-socket-perms = {
    description = "Make rootless podman socket reachable for uid 1000";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "podman-socket-chmod" ''
        SOCK=/run/user/1001/podman/podman.sock
        [ -S "$SOCK" ] || exit 0
        MODE=$(stat -c '%a' "$SOCK")
        if [ "$MODE" != "666" ]; then
          echo "podman socket mode $MODE -> 666" >&2
          chmod 0666 "$SOCK"
        fi
      '';
    };
  };

  systemd.timers.podman-socket-perms = {
    description = "Poll rootless podman socket permissions every 30s";
    wantedBy = ["multi-user.target"];
    timerConfig = {
      OnBootSec = "10s";
      OnUnitActiveSec = "30s";
      Unit = "podman-socket-perms.service";
    };
  };
}
