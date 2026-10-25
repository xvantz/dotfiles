{ pkgs, config, ... }:
let
  # Wrapper lives in a store script (not inline in ExecStart): systemd expands
  # $VAR/${VAR} in unit lines, so any shell $ there gets eaten (proven
  # 2026-10-26: `${line#*=}` became empty, ttyd exited 255). File contents are
  # passed through untouched - single Nix escaping layer only.
  startScript = pkgs.writeShellScript "driftty-terminal-start" ''
    set -eu
    f=${config.sops.secrets.driftty_env.path}
    if [ ! -r "$f" ]; then echo "missing secret file $f" >&2; exit 1; fi
    line=$(grep -m1 "=" "$f" || cat "$f")
    pw="''${line#*=}"
    exec ${pkgs.xv-driftty-terminal}/bin/driftty-terminal -p 7681 -c "driftty:$pw" ${pkgs.tmux}/bin/tmux new-session -A -s default
  '';
in
{
  # Native driftty-terminal, no podman gateway.
  # Home user service: same UID as the tmux server, no mounts, no version skew.
  # Password reuses the existing sops key driftty_env (same secrets.yaml, no
  # sops changes): home-manager sops-nix decrypts as the user into
  # /run/user/*/secrets, so no owner juggling is needed.
  # Full PATH in Environment: if this service creates the tmux server first
  # (fresh boot, browser before any shell), plugins resolve interpreters via
  # the server env - bare systemd PATH means 127 for every plugin.
  sops.secrets.driftty_env = { };

  systemd.user.services.driftty-terminal = {
    Unit = {
      Description = "driftty-terminal native web terminal for tmux";
    };
    Service = {
      Type = "simple";
      Environment = [
        "TERM=xterm-256color"
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/home/xvantz/.nix-profile/bin:/etc/profiles/per-user/xvantz/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin"
      ];
      # driftty_env is the old podman env file (KEY=value). The parser takes
      # the value after the first '=' (works with any var name, keeps '='
      # padding); a bare password file without '=' works too.
      # Zero-exposure check on host (prints only the var NAME, never the value):
      #   cut -d= -f1 "$(nix --extra-experimental-features 'nix-command flakes' eval --raw .#homeConfigurations.xvantz.config.sops.secrets.driftty_env.path)"
      ExecStart = startScript;
      WorkingDirectory = "%h";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
