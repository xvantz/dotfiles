{...}: {
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
