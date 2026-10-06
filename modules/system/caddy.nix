{
  pkgs,
  config,
  ...
}: let
  caddyWithCloudflare = pkgs.caddy.withPlugins {
    plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
    hash = "sha256-xRJ5evsAJ2akg47j3Bt6YDXJOgX88B/rKNP50KSVyNY=";
  };
in {
  sops.secrets.cloudflare_env = {
    owner = "caddy";
  };

  systemd.services.caddy = {
    after = ["time-sync.target" "sops-install-secrets.service"];
    wants = ["time-sync.target" "sops-install-secrets.service"];
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

    virtualHosts."docker.827482.xyz" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_TOKEN}
          resolvers 1.1.1.1
        }
        reverse_proxy http://127.0.0.1:9999
      '';
    };

    virtualHosts."terminal.827482.xyz" = {
      extraConfig = ''
        @tailnet remote_ip 100.64.0.0/10
        handle @tailnet {
          reverse_proxy http://127.0.0.1:7681
        }
        handle {
          respond "Access requires Tailscale" 403
        }
        tls {
          dns cloudflare {env.CLOUDFLARE_TOKEN}
          resolvers 1.1.1.1
        }
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
