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
}
