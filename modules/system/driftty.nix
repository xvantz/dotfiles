{ pkgs, config, ... }: {
  sops.secrets.driftty_env = {
    owner = "root";
  };

  virtualisation.oci-containers.containers.driftty = {
    image = "ghcr.io/mdp/driftty-gateway:edge";
    ports = [ "127.0.0.1:7681:7681" ];
    volumes = [
      "/tmp/tmux-1000:/run/host-tmux:ro"
      "/etc/driftty/tmux-wrapper:/usr/local/lib/driftty-local/bin/tmux:ro"
    ];
    cmd = [ "--local-tmux" "/run/host-tmux/default" ];
    environmentFiles = [ config.sops.secrets.driftty_env.path ];
    extraOptions = [ "--pull=always" ];
  };

  # Upstream wrapper in the image only knows server 3.6, everything else
  # (including our 3.7c) is routed to tmux-3.5a -> protocol mismatch ->
  # "server exited unexpectedly". Fix by adding 3.7 to the case.
  # Source: gateway/src/local-tmux.ts + docker/local-tmux-wrapper.sh
  # Newer gateways may not set DRIFTTY_LOCAL_TMUX_SOCKET at all (passing
  # -S directly or nothing), so never fail hard: fall back to -S from args
  # or to our known mount point.
  environment.etc."driftty/tmux-wrapper" = {
    mode = "0555";
    text = ''
      #!/bin/sh
      set -eu

      sock="''${DRIFTTY_LOCAL_TMUX_SOCKET:-}"
      has_flag=0
      for a in "$@"; do
        if [ "$a" = "-S" ]; then has_flag=1; break; fi
      done
      if [ "$has_flag" -eq 0 ]; then
        if [ -z "$sock" ]; then sock="/run/host-tmux/default"; fi
        set -- -S "$sock" "$@"
      else
        # socket path follows -S in args; fall back to env/default if unparsable
        next_is_sock=0
        for a in "$@"; do
          if [ "$next_is_sock" -eq 1 ]; then sock="$a"; break; fi
          if [ "$a" = "-S" ]; then next_is_sock=1; fi
        done
        if [ -z "$sock" ]; then sock="/run/host-tmux/default"; fi
      fi

      tmux_client=/usr/bin/tmux
      server_version=$(
        "$tmux_client" -S "$sock" \
          display-message -p '#{version}' 2>/dev/null || true
      )
      case "$server_version" in
        3.7*|3.6*) ;;
        *) tmux_client=/usr/local/bin/tmux-3.5a ;;
      esac

      exec "$tmux_client" "$@"
    '';
  };

  # tmux server must be alive before the container starts,
  # otherwise podman creates an empty directory instead of the socket
  systemd.services.driftty-tmux-keepalive = {
    description = "keep tmux session alive for driftty";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "xvantz";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -A -s default -c /home/xvantz";
    };
  };

  systemd.services.podman-driftty = {
    after = [ "driftty-tmux-keepalive.service" ];
    wants = [ "driftty-tmux-keepalive.service" ];
  };
}
