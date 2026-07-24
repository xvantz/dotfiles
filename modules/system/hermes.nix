{
  pkgs,
  config,
  ...
}: {
  sops.secrets.hermes_env = {
    owner = "xvantz";
  };

  sops.secrets.forgejo_env = {
    owner = "xvantz";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    user = "hermes";
    group = "users";

    container = {
      enable = true;
      backend = "podman";
      image = "ubuntu:24.04";
      hostUsers = ["xvantz"];
      extraOptions = [
        "--env"
        "HERMES_UID=1000"
        "--env"
        "HERMES_GID=100"
        "--env"
        "GIT_ASKPASS=${pkgs.writeShellScript "git-askpass" "echo $FORGEJO_TOKEN"}"
      ];
    };

    extraDependencyGroups = ["messaging" "voice"];
    extraPackages = with pkgs; [go zig bun buf golangci-lint gitea-mcp-server gopls typescript-language-server pyright rust-analyzer zls nil];

    documents = {
      "OBSIDIAN_MEMORY.md" = ''
        Hermes Agent persistent storage:
        - Memory: /brain/3. Resources/Hermes Agent/Memory.md
        - Skills: /brain/3. Resources/Hermes Agent/Skills/
      '';
    };

    settings = {
      model = {
        default = "deepseek-v4-flash";
        provider = "opencode-go";
        base_url = "https://opencode.ai/zen/go/v1";
        api_mode = "chat_completions";
      };

      auxiliary.vision = {
        provider = "gemini";
        model = "gemini-3.1-flash-lite";
      };

      web = {
        backend = "tavily";
        search_backend = "tavily";
        extract_backend = "tavily";
      };

      messaging.discord.enabled = true;

      display = {
        compact = false;
        personality = "technical";
        resume_display = "full";
        busy_input_mode = "interrupt";
        tui_auto_resume_recent = false;
        bell_on_complete = false;
        show_reasoning = false;
        streaming = true;
        timestamps = false;
        final_response_markdown = "strip";
        persistent_output = true;
        persistent_output_max_lines = 200;
        inline_diffs = true;
        file_mutation_verifier = true;
        show_cost = true;
        skin = "default";
        language = "en";
        tui_status_indicator = "kaomoji";
        user_message_preview = {
          first_lines = 2;
          last_lines = 2;
        };
        interem_assistant_messages = true;
        tool_progress_command = true;
        tool_progress_overrides = {};
        tool_preview_length = 0;
        ephemeral_system_ttl = 0;
        platforms = {};
        copy_shortcut = "auto";
        tool_progress = "all";
        cleanup_progress = false;
        background_process_notifications = "all";
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      toolsets = ["all"];

      discord = {
        require_mention = false;
        free_response_channels = "";
        allowed_channels = "";
        auto_thread = true;
        thread_require_mention = false;
        history_backfill = true;
        history_backfill_limit = 50;
        reactions = true;
        channel_prompts = {};
        dm_role_auth_guide = "";
        server_actions = "";
      };

      telegram = {
        require_mention = false;
        free_response_channels = "";
        allowed_channels = "";
        auto_thread = true;
        thread_require_mention = false;
        history_backfill = true;
        history_backfill_limit = 50;
        reactions = true;
        channel_prompts = {};
        dm_role_auth_guide = "";
        server_actions = "";
      };

      worktree = false;

      platform_toolsets = {
        cli = "hermes-cli";
        discord = "hermes-discord";
      };

      group_sessions_per_user = true;

      session_reset = {
        mode = "none";
      };

      lsp = {
        enabled = true;
        wait_mode = "document";
        wait_timeout = 5.0;
        install_strategy = "auto";
        servers = {};
      };

      approvals = {
        mode = "smart";
      };

      terminal = {
        backend = "local";
        cwd = ".";
      };

      compression = {
        enabled = true;
        threshold = 0.70;
        target_ratio = 0.40;
      };

      stt = {
        enabled = true;
        provider = "local";
        local = {
          model = "base";
        };
      };
    };

    environmentFiles = [config.sops.secrets.hermes_env.path config.sops.secrets.forgejo_env.path];

    mcpServers = {
      filesystem-obsidian = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@modelcontextprotocol/server-filesystem" "/brain"];
      };

      filesystem-projects = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@modelcontextprotocol/server-filesystem" "/projects"];
      };

      filesystem-dotfiles = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@modelcontextprotocol/server-filesystem" "/dotfiles"];
      };

      playwright = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@playwright/mcp@latest" "--headless"];
      };

      github = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@modelcontextprotocol/server-github"];
        env.GITHUB_PERSONAL_ACCESS_TOKEN = ''${GITHUB_TOKEN}'';
      };

      fetch = {
        enabled = true;
        command = "${pkgs.uv}/bin/uvx";
        args = ["mcp-server-fetch"];
      };

      figma = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "figma-developer-mcp" "--stdio"];
        env.FIGMA_API_KEY = ''${FIGMA_API_KEY}'';
      };

      forgejo = {
        enabled = true;
        command = "${pkgs.gitea-mcp-server}/bin/gitea-mcp";
        args = [
          "-t"
          "stdio"
          "-H"
          "https://git.827482.xyz"
          "-T"
          ''${FORGEJO_TOKEN}''
        ];
      };

      ts-docs-mcp = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "ts-docs-mcp"];
        env.GITHUB_TOKEN = ''${GITHUB_TOKEN}'';
      };

      agent-lsp = {
        enabled = true;
        command = "${pkgs.xv-agent-lsp}/bin/agent-lsp";
        args = [
          "go:gopls"
          "typescript:typescript-language-server,--stdio"
          "python:pyright-langserver,--stdio"
          "rust:rust-analyzer"
          "zig:zls"
          "nix:nil"
        ];
      };

      pm = {
        enabled = true;
        command = "${config.services.pm.package}/bin/pm-mcp";
        env.PM_DIR = "/data/pm";
      };
    };

    container.extraVolumes = [
      "/home/xvantz/Documents/Obsidian:/brain:Z"
      ''"/home/xvantz/Documents/Obsidian/3. Resources/Hermes Agent/SOUL.md:/data/.hermes/SOUL.md:Z"''
      ''"/home/xvantz/Documents/Obsidian/3. Resources/Hermes Agent/USER.md:/data/workspace/USER.md:Z"''
      "/home/xvantz/projects/public:/projects:rw"
      "/home/xvantz/.dotfiles:/dotfiles:rw"
      "/home/xvantz/Documents/pm:/data/pm:Z"
    ];

    restart = "always";
    restartSec = 5;
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
