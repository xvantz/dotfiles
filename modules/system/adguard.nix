{...}: let
  hostIP = "100.95.144.120";
in {
  services.adguardhome = {
    enable = true;
    openFirewall = false;
    host = "127.0.0.1";
    port = 8345;

    settings = {
      dns = {
        bind_hosts = ["127.0.0.1" "100.95.144.120"];
        port = 53;

        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
          "https://dns.quad9.net/dns-query"
        ];
        bootstrap_dns = ["1.1.1.1" "9.9.9.9"];
        fallback_dns = ["1.0.0.1" "149.112.112.112"];
      };

      filtering = {
        filtering_enabled = true;
        blocking_ipv4 = "0.0.0.0";
        blocking_ipv6 = "::";
        rewrites = [
          {
            domain = "git.xvantz.me";
            answer = hostIP;
            enabled = true;
          }
        ];
      };

      querylog = {
        enabled = true;
        interval = "720h";
      };

      statistics = {
        enabled = true;
        interval = "24h";
      };
    };
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "127.0.0.1 9.9.9.9 1.1.1.1";
        DNSStubListener = false;
        Domains = "~.";
        LLMNR = false;
      };
    };
  };
}
