{
  pkgs,
  config,
  ...
}: {
  sops.secrets.hermes_env = {
    owner = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    user = "xvantz";
    group = "users";
    createUser = false;

    container = {
      enable = true;
      backend = "podman";
      image = "ubuntu:24.04";
      hostUsers = ["xvantz"];
    };

    extraDependencyGroups = ["messaging"];

    settings = {
      model = {
        default = "deepseek-v4-flash";
        provider = "opencode-go";
        base_url = "https://opencode.ai/zen/go/v1";
        api_mode = "chat_completions";
      };

      auxiliary.vision = {
        provider = "openai";
        model = "qwen3-vl:4b-instruct-q4_K_M";
        base_url = "http://localhost:11434/v1";
        api_key = "ollama";
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
        interim_assistant_messages = true;
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
        require_mention = true;
        free_response_channels = "";
        allowed_channels = "";
        auto_thread = true;
        thread_require_mention = false;
        history_backfill = true;
        history_backfill_limit = 50;
        reactions = true;
        channel_prompts = {};
        dm_role_auth_guild = "";
        server_actions = "";
      };

      worktree = true;

      platform_toolsets = {
        cli = "hermes-cli";
        discord = "hermes-discord";
      };

      group_sessions_per_user = true;

      session_reset = {
        mode = "both";
        idle_minutes = 1440;
        at_hour = 4;
      };

      lsp = {
        enabled = true;
        wait_mode = "document";
        wait_timeout = 5.0;
        install_strategy = "auto";
        servers = {};
      };

      terminal = {
        backend = "local";
        cwd = ".";
      };
    };

    environmentFiles = [config.sops.secrets.hermes_env.path];
    # authFile = "/home/xvantz/hermes/work/auth.json";

    mcpServers.filesystem-obsidian = {
      enabled = true;
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@modelcontextprotocol/server-filesystem" "/brain"];
    };

    mcpServers.filesystem-projects = {
      enabled = true;
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@modelcontextprotocol/server-filesystem" "/projects"];
    };

    container.extraVolumes = [
      "/home/xvantz/Documents/Obsidian:/brain:Z"
      "/home/xvantz/projects/.hermes_share:/projects:rw"
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
