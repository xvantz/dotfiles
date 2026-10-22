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
        autocomplete = "brave";
      };

      outgoing = {
        request_timeout = 8.0;
        max_request_timeout = 15.0;
        pool_connections = 50;
        enable_http2 = true;
        retries = 1;
        useragent_suffix = "xvantz-private";
      };

      engines = [
        { name = "ahmia"; disabled = true; }
        { name = "torch"; disabled = true; }
        { name = "google cse"; disabled = true; }
        { name = "google"; disabled = true; }
        { name = "bing"; disabled = true; }
      ];
    };
  };

  systemd.services.searx = {
    after = [ "sops-install-secrets.service" "redis-searx.service" "network-online.target" ];
    wants = [ "sops-install-secrets.service" "redis-searx.service" "network-online.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
