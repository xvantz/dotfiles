{
  pkgs,
  config,
  ...
}: let
  hindsightDir = "/var/lib/hindsight";
in {
  virtualisation.oci-containers.containers.hindsight = {
    image = "ghcr.io/vectorize-io/hindsight:latest";
    ports = ["127.0.0.1:8891:8888" "127.0.0.1:9999:9999"];
    volumes = ["${hindsightDir}/data:/home/hindsight/.pg0:Z"];
    extraOptions = ["--pull=always"];
    environment = {
      HINDSIGHT_API_LLM_PROVIDER = "openai";
      HINDSIGHT_API_LLM_BASE_URL = "https://opencode.ai/zen/go/v1";
      HINDSIGHT_API_LLM_MODEL = "mimo-v2.5";
    };
    # Use environmentFiles for secrets
    environmentFiles = [config.sops.secrets.hindsight_env.path];
  };

  systemd.services.hindsight-data = {
    description = "Ensure Hindsight data directory exists";
    before = ["container-hindsight.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/mkdir -p ${hindsightDir}/data";
    };
  };
}
