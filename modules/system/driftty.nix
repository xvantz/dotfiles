{ pkgs, config, ... }: {
  sops.secrets.driftty_env = {
    owner = "root";
  };

  virtualisation.oci-containers.containers.driftty = {
    image = "ghcr.io/mdp/driftty-gateway:edge";
    ports = [ "127.0.0.1:7681:7681" ];
    volumes = [
      "/tmp/tmux-1000:/run/host-tmux:ro"
    ];
    cmd = [ "--local-tmux" "/run/host-tmux/default" ];
    environmentFiles = [ config.sops.secrets.driftty_env.path ];
    extraOptions = [ "--pull=always" ];
  };

  # tmux сервер должен жить до старта контейнера,
  # иначе podman создаст пустую директорию вместо сокета
  systemd.services.driftty-tmux-keepalive = {
    description = "keep tmux session alive for driftty";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "xvantz";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main -c /home/xvantz";
    };
  };

  systemd.services.podman-driftty = {
    after = [ "driftty-tmux-keepalive.service" ];
    wants = [ "driftty-tmux-keepalive.service" ];
  };
}
