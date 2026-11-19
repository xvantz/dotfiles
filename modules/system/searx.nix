{
  config,
  lib,
  ...
}: {
  sops.secrets.searx_env = {
    owner = "xvantz";
    restartUnits = ["podman-searxng.service"];
  };

  virtualisation.oci-containers.containers.searxng = {
    image = "docker.io/searxng/searxng:2026.11.19-368baa340";
    ports = ["127.0.0.1:8888:8080"];
    volumes = [
      # Read-only settings from the nix store; the secret comes from the env file.
      "${./searxng/settings.yml}:/etc/searxng/settings.yml:ro"
      # Silences "missing config file: /etc/searxng/limiter.toml" (limiter is off).
      "${./searxng/limiter.toml}:/etc/searxng/limiter.toml:ro"
    ];
    environmentFiles = [
      config.sops.secrets.searx_env.path
    ];
    extraOptions = [
      "--pull=missing"
      "--volume"
      "searxng-cache:/var/cache/searxng"
    ];
  };

  # The env file is read by podman at container start, so the unit must not come up before
  # sops has written /run/secrets/searx_env. mkAfter keeps the module's own ordering
  systemd.services."podman-searxng" = {
    after = lib.mkAfter ["sops-install-secrets.service"];
    wants = lib.mkAfter ["sops-install-secrets.service"];
  };
}
