{pkgs, ...}: {
  programs.nixvim = {
    plugins.overseer = {
      enable = true;

      settings = {
        strategy = "terminal";
        task_list = {
          direction = "bottom";
          min_height = 15;
          max_height = 0.4;
          default_detail = 2;
        };
        templates = ["builtin"];
      };

      keys = [
        {
          mode = "n";
          key = "<leader>rr";
          action = "<cmd>OverseerRun<CR>";
          options.desc = "Overseer: Run task";
        }
        {
          mode = "n";
          key = "<leader>rt";
          action = "<cmd>OverseerToggle!<CR>";
          options.desc = "Overseer: Toggle panel";
        }
        {
          mode = "n";
          key = "<leader>rs";
          action.__raw = ''
            function()
              vim.ui.input({
                prompt = "Overseer shell> ",
                default = "",
              }, function(cmdline)
                if cmdline == nil or cmdline:match("^%s*$") then
                  print("Task cancelled or empty.")
                  return
                end
                vim.cmd("OverseerShell " .. cmdline)
              end)
            end
          '';
          options.desc = "Overseer: run shell command";
        }
      ];
    };

    extraConfigLua = ''
      local overseer = require("overseer")

      -- npm run dev
      overseer.register_template({
        name = "npm run dev",
        builder = function()
          return {
            cmd = { "npm" },
            args = { "run", "dev" },
            cwd = vim.fn.getcwd(),
          }
        end,
        tags = { overseer.TAG.BUILD },
      })

      -- python current file
      overseer.register_template({
        name = "python current file",
        builder = function()
          return {
            cmd = { "python" },
            args = { vim.fn.expand("%:p") },
          }
        end,
      })

      -- go run .
      overseer.register_template({
        name = "go run .",
        builder = function()
          return {
            cmd = { "go" },
            args = { "run", "." },
            cwd = vim.fn.getcwd(),
          }
        end,
      })

      -- cargo run
      overseer.register_template({
        name = "cargo run",
        builder = function()
          return {
            cmd = { "cargo" },
            args = { "run" },
            cwd = vim.fn.getcwd(),
          }
        end,
      })
    '';
  };
}
