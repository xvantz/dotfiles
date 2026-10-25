{ config, pkgs, ... }:
{
  # Native driftty-terminal, no podman gateway (modules/system/driftty.nix removed).
  # System service with User=xvantz on purpose:
  # - same UID = same tmux socket /run/user/1000/tmux-1000, no mounts
  # - reuses the existing root-owned sops secret driftty_env with zero sops
  #   changes (a user unit could not read it: home-manager sops is a separate
  #   namespace, and the system secret file is root-only)
  # - starts at boot: phone works without desktop login, no lingering needed
  # Full PATH in Environment: if this service creates the tmux server first
  # (fresh boot, browser before any shell), plugins resolve interpreters via
  # the server env - bare systemd PATH means 127 for every plugin.
  sops.secrets.driftty_env = {
    owner = "root";
  };

  systemd.services.driftty-terminal = {
    description = "driftty-terminal native web terminal for tmux";
    after = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    wants = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "xvantz";
      Environment = [
        "TERM=xterm-256color"
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/home/xvantz/.nix-profile/bin:/etc/profiles/per-user/xvantz/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin"
      ];
      # driftty_env is the old podman env file (KEY=value). The parser takes
      # the value after the first '=' (works with any var name, keeps '='
      # padding); a bare password file without '=' works too.
      # Zero-exposure check on host (prints only the var NAME, never the value):
      #   cut -d= -f1 /run/secrets/driftty_env
      ExecStart = ''${pkgs.bash}/bin/bash -c 'f=${config.sops.secrets.driftty_env.path}; line=$(grep -m1 "=" "$f" || cat "$f"); pw="''${line#*=}"; exec ${pkgs.xv-driftty-terminal}/bin/driftty-terminal -p 7681 -c "driftty:$pw" ${pkgs.tmux}/bin/tmux new-session -A -s default' '';
      WorkingDirectory = "/home/xvantz";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
