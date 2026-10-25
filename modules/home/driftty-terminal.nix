{ pkgs, config, ... }:
{
  # Native driftty-terminal (no podman gateway). Replaces modules/system/driftty.nix.
  # Password: sops secret `driftty_password` (file content is one line:
  #   DRIFTTY_PASSWORD=<a-z0-9, 30 chars>
  # add it on the host with `sops ~/.dotfiles/secrets.yaml` before switching).
  # Rollback: stop this unit, restore gateway file from git, start podman-driftty.
  sops.secrets.driftty_password = { };

  systemd.user.services.driftty-terminal = {
    Unit = {
      Description = "driftty-terminal native web terminal for tmux";
    };
    Service = {
      Type = "simple";
      EnvironmentFile = config.sops.secrets.driftty_password.path;
      ExecStart = ''${pkgs.bash}/bin/bash -c 'exec ${pkgs.xv-driftty-terminal}/bin/driftty-terminal -p 7681 -c "driftty:$DRIFTTY_PASSWORD" ${pkgs.tmux}/bin/tmux new-session -A -s default' '';
      WorkingDirectory = "%h";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
