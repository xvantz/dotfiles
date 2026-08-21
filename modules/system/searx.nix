{config, ...}: {
  sops.secrets.searx_env = {
    owner = "searx";
  };

  services.searx = {
    enable = true;

    environmentFile = config.sops.secrets.searx_env.path;

    redisCreateLocally = true;

    settings = {
      use_default_settings = true;

      server = {
        port = 8888;
        bind_address = "127.0.0.1";
        secret_key = "\$SEARX_SECRET_KEY";
      };

      search = {
        safe_search = 0;
        languages = ["ru" "en"];
        formats = ["html" "json" "csv"];
      };
    };
  };

  systemd.services.searx = {
    after = ["sops-install-secrets.service" "redis-searx.service"];
    wants = ["sops-install-secrets.service" "redis-searx.service"];
  };
}
