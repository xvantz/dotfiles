{
  pkgs,
  config,
  ...
}: let
  caddyWithCloudflare = pkgs.caddy.withPlugins {
    plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
    hash = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
  };
in {
  sops.secrets.cloudflare_env = {
    owner = "caddy";
  };

  services.caddy = {
    enable = true;
    package = caddyWithCloudflare;
    environmentFile = config.sops.secrets.cloudflare_env.path;

    virtualHosts."git.827482.xyz" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_TOKEN}
          resolvers 1.1.1.1
        }
        reverse_proxy http://127.0.0.1:2000
      '';
    };

    virtualHosts."navidrome.827482.xyz" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_TOKEN}
          resolvers 1.1.1.1
        }
        reverse_proxy http://127.0.0.1:4533
      '';
    };

    virtualHosts."*.827482.xyz" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_TOKEN}
          resolvers 1.1.1.1
        }
        reverse_proxy http://127.0.0.1:30080 {
          header_up X-Forwarded-Proto https
        }
      '';
    };
  };
}
