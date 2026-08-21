{
  pkgs,
  config,
  ...
}: {
  sops.secrets.hindsight_env = {
    owner = "xvantz";
  };

  virtualisation.oci-containers.containers.hindsight = {
    image = "ghcr.io/vectorize-io/hindsight:latest";
    ports = ["127.0.0.1:8891:8888" "127.0.0.1:9998:9999"];
    volumes = ["hindsight-data:/home/hindsight/.pg0"];
    extraOptions = ["--pull=always"];
    environment = {
      HINDSIGHT_API_LLM_PROVIDER = "openai";
      HINDSIGHT_API_LLM_BASE_URL = "https://opencode.ai/zen/go/v1";
      HINDSIGHT_API_LLM_MODEL = "mimo-v2.5";
    };
    environmentFiles = [config.sops.secrets.hindsight_env.path];
  };
}
