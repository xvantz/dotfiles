{
  pkgs,
  config,
  ...
}: let
  cfg = config.services.forgejo;
  srv = cfg.settings.server;
  defaultActUrl = "https://data.forgejo.org";
in {
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
      name = "nixos-native-runner";

      url = defaultActUrl;

      settings = {
        runner = {
          labels = [
            "ubuntu-latest:docker://node:20-alpine"
            "docker:docker://node:20-alpine"
            "native:host"
          ];
        };
      };
    };
  };
}
