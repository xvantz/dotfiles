{
  pkgs,
  config,
  ...
}: let
  srv = config.services.forgejo.settings.server;
in {
  sops.secrets.forgejo_runner_token = {};

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
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "nixos-runner";
      url = "http://127.0.0.1:2000/";
      tokenFile = config.sops.secrets.forgejo_runner_token.path;
      labels = ["ubuntu-latest:docker://node:20-bookworm"];
      settings = {
        container = {
          network = "";
          privileged = false;
          options = "--memory=4g --cpus=2";
        };
        log.level = "info";
      };
    };
  };
}
