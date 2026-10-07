{ pkgs, ... }: {
  # Browser terminal #2 (ttyd) next to driftty for evaluation.
  # Attaches straight to the shared `default` tmux session (-A creates it
  # if missing), so phone and desktop always see the same shell.
  # Tailnet-only via Caddy, same gate as terminal.827482.xyz.
  systemd.services.ttyd-terminal2 = {
    description = "ttyd browser terminal (shared tmux session)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "xvantz";
      WorkingDirectory = "/home/xvantz";
      ExecStart = "${pkgs.ttyd}/bin/ttyd -p 7682 -i 127.0.0.1 ${pkgs.tmux}/bin/tmux -S /tmp/tmux-1000/default new-session -A -s default";
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
