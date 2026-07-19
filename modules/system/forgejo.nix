{
  pkgs,
  config,
  ...
}: let
  srv = config.services.forgejo.settings.server;
in {
  sops.secrets = {
    forgejo_runner_token = {};
    forgejo_ssh_key = {
      path = "/var/lib/forgejo/.ssh/id_ed25519";
      owner = "forgejo";
    };
    github_admin_env = {
      owner = "xvantz";
    };
    forgejo_admin_env = {
      owner = "xvantz";
    };
  };

  services.forgejo = {
    enable = true;
    database.type = "postgres";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.827482.xyz";
        ROOT_URL = "https://${srv.DOMAIN}/";
        HTTP_PORT = 2000;
        HTTP_ADDR = "127.0.0.1";
      };
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
      mirror = {
        SSH_KEY_FILE = "/var/lib/forgejo/.ssh/id_ed25519";
      };
      webhook = {
        ALLOWED_HOST_LIST = "127.0.0.1, localhost";
      };
    };
  };

  systemd.services.forgejo.postStart = ''
    ${pkgs.openssh}/bin/ssh-keyscan github.com 2>/dev/null >> /var/lib/forgejo/.ssh/known_hosts || true
  '';

  services = {
    gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.default = {
        enable = true;
        name = "nixos-runner";
        url = "http://127.0.0.1:2000/";
        tokenFile = config.sops.secrets.forgejo_runner_token.path;
        labels = [
          "ubuntu-latest:docker://node:lts-bookworm"
          "ubuntu-22.04:docker://node:lts-bookworm"
          "node:docker://node:lts-bookworm"
          "python:docker://python:3.12-bookworm"
          "go:docker://golang:1.23-bookworm"
        ];
        settings = {
          container = {
            network = "host";
            privileged = false;
            options = "--memory=4g --cpus=2";
            docker_host = "automount";
          };
          log.level = "info";
        };
      };
    };

    forgejo-sync = {
      enable = true;

      forgejo = {
        url = "http://localhost:2000";
        tokenFile = config.sops.secrets.forgejo_admin_env.path;
      };

      platforms.github = {
        enable = true;
        tokenFile = config.sops.secrets.github_admin_env.path;
      };

      import = {
        enable = true;
        schedule = "hourly";
      };

      pushMirrors.enable = true;
      autoCreate.enable = true;
    };
  };

  environment.systemPackages = [config.services.forgejo-sync.package];
}
