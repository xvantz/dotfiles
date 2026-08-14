{
  pkgs,
  config,
  inputs,
  ...
}:
let
  hermesWithPython = inputs.hermes-agent.packages.${pkgs.system}.default.override {
    extraPythonPackages = with pkgs.python312Packages; [
      razdel
      pymorphy3
    ];
  };
in {
  sops.secrets.hermes_env = {
    owner = "xvantz";
  };

  sops.secrets.forgejo_env = {
    owner = "xvantz";
  };

  services.hermes-agent = {
    enable = true;
    package = hermesWithPython;
    addToSystemPackages = true;
    user = "hermes";
    group = "users";

    container = {
      enable = true;
      backend = "podman";
      image = "docker.io/library/ubuntu:26.04";
      hostUsers = ["xvantz"];
      extraOptions = [
        "--shm-size"
        "512m"
        "--env"
        "HERMES_UID=1000"
        "--env"
        "HERMES_GID=100"
        "--env"
        "GIT_ASKPASS=${pkgs.writeShellScript "git-askpass" "echo $FORGEJO_TOKEN"}"
        "--env"
        "SEARXNG_URL=http://localhost:8888"
        "--env"
        "FIRECRAWL_API_URL=http://localhost:8889"
        "--env"
        "AGENT_BROWSER_EXECUTABLE_PATH=${pkgs.writeShellScriptBin "agent-browser-chromium" ''
          args=("$@")
          has_url=0
          for a in "''${args[@]}"; do
            case "$a" in
              -*) ;;
              *) has_url=1 ;;
            esac
          done
          if [ "$has_url" -eq 0 ]; then
            exec ${pkgs.chromium}/bin/chromium --remote-allow-origins=* "$@" "about:blank"
          else
            exec ${pkgs.chromium}/bin/chromium --remote-allow-origins=* "$@"
          fi
        ''}/bin/agent-browser-chromium"
        "--env"
        "PATH=${pkgs.lib.makeBinPath config.services.hermes-agent.extraPackages}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
    };

    extraDependencyGroups = ["messaging" "voice" "edge-tts" "firecrawl"];
    extraPackages = with pkgs; [go zig bun buf golangci-lint gitea-mcp-server gopls typescript-language-server pyright rust-analyzer zls nixd svelte-language-server yaml-language-server bash-language-server lua-language-server terraform-ls dockerfile-language-server yt-dlp chromium docker-client docker-compose pnpm fontconfig dejavu_fonts];

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
        backend = "searxng";
        search_backend = "searxng";
        extract_backend = "firecrawl";
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

      skills = {
        external_dirs = [
          "/dotfiles/modules/system/hermes/skills"
        ];
      };

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
        args = [
          "-y"
          "@playwright/mcp@latest"
          "--headless"
          # "--config"
          # "/data/.hermes/playwright-mcp.json"
          "--executable-path"
          "${pkgs.chromium}/bin/chromium"
        ];
        env.FONTCONFIG_FILE = "${pkgs.fontconfig}/etc/fonts/fonts.conf";
        env.XDG_DATA_DIRS = "${pkgs.dejavu_fonts}/share";
      };

      github = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@modelcontextprotocol/server-github"];
        env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_TOKEN}";
      };

      figma = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "figma-developer-mcp" "--stdio"];
        env.FIGMA_API_KEY = "\${FIGMA_API_KEY}";
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
          "\${FORGEJO_TOKEN}"
        ];
      };

      ts-docs-mcp = {
        enabled = true;
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "ts-docs-mcp"];
        env.GITHUB_TOKEN = "\${GITHUB_TOKEN}";
      };

      pm = {
        enabled = true;
        command = "${pkgs.writeShellScriptBin "pm-diag" ''
          echo "=== DIAG: starting pm-mcp ===" >&2
          echo "PWD: $(pwd)" >&2
          echo "PM_DIR: ${builtins.getEnv "PM_DIR"}" >&2
          echo "PATH: $PATH" >&2
          echo "HOME: $HOME" >&2
          echo "USER: $USER" >&2
          env >&2
          exec ${config.services.pm.package}/bin/pm-mcp --dir /data/pm
        ''}/bin/pm-diag";
      };
    };

    container.extraVolumes = [
      "/home/xvantz/Documents/Obsidian:/brain:Z"
      ''"/home/xvantz/Documents/Obsidian/3. Resources/Hermes Agent/SOUL.md:/data/.hermes/SOUL.md:Z"''
      ''"/home/xvantz/Documents/Obsidian/3. Resources/Hermes Agent/USER.md:/data/workspace/USER.md:Z"''
      "/home/xvantz/projects/public:/projects:rw"
      "/home/xvantz/.dotfiles:/dotfiles:rw"
      "/home/xvantz/Documents/pm:/data/pm:Z"
      "/run/user/1001/podman/podman.sock:/var/run/docker.sock"
    ];

    restart = "always";
    restartSec = 5;
  };

  systemd.services.hermes-agent = {
    after = ["sops-install-secrets.service"];
    wants = ["sops-install-secrets.service"];
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
