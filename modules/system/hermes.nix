{pkgs, ...}: {
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    container = {
      enable = true;
      backend = "podman";
      image = "ubuntu:24.04";

      hostUsers = ["xvantz"];
    };

    settings = {
      model = {
        default = "deepseek-v4-flash";
        provider = "opencode-go";
        base_url = "https://opencode.ai/zen/go/v1";
        api_mode = "chat_completions";
      };

      display = {
        personality = "technical";
      };
    };

    environmentFiles = ["/home/xvantz/.config/hermes/.env"];

    mcpServers.filesystem-obsidian = {
      enabled = true;
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@modelcontextprotocol/server-filesystem" "/brain"];
    };

    container.extraVolumes = [
      "/home/xvantz/Documents/Obsidian:/brain:Z"
    ];
  };

  security.sudo.extraRules = [
    {
      users = ["xvantz"];
      commands = [
        {
          command = "/run/current-system/sw/bin/podman";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
