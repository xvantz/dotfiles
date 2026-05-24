{config, ...}: {
  services.podman = {
    enable = true;

    containers = {
      hermes-work = {
        image = "docker.io/nousresearch/hermes-agent:latest";

        cmd = ["gateway" "run"];

        environmentFile = ["${config.xdg.configHome}/hermes/.env"];

        environment = {
          HERMES_DASHBOARD = "1";
          HERMES_UID = "1000";
          HERMES_GID = "100";
        };

        volumes = [
          "${config.home.homeDirectory}/hermes/work:/opt/data"
          "${config.home.homeDirectory}/Documents/Obsidian:/brain"
        ];

        ports = [
          "8642:8642"
          "9119:9119"
        ];

        extraOptions = [
          "--memory=4g"
          "--cpus=2.0"
          "--network=host"
        ];
      };
    };
  };
}
