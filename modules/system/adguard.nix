{...}: let
  hostIP = "127.0.0.1";
in {
  services.adguardhome = {
    enable = true;
    openFirewall = false;

    settings = {
      http = {
        address = "127.0.0.1:8345";
        session_ttl = "360h";
      };

      dns = {
        bind_host = "0.0.0.0";
        port = 53;

        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
          "https://dns.quad9.net/dns-query"
        ];
        bootstrap_dns = ["1.1.1.1" "9.9.9.9"];
        fallback_dns = ["1.0.0.1" "149.112.112.112"];

        rewrites = [
          {
            domain = "git.xvantz.me";
            answer = hostIP;
          }
        ];

        blocking_mode = "default";
        rate_limit = 100;
        ednscp_enable = true;
      };

      filtering = {
        filtering_enabled = true;
        blocking_ipv4 = "0.0.0.0";
        blocking_ipv6 = "::";
      };

      querylog = {
        enabled = true;
        interval = "720h";
      };

      statistics = {
        enabled = true;
        interval = 24;
      };
    };
  };
}
