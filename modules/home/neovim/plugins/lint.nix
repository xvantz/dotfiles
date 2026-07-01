{pkgs, ...}: {
  programs.nixvim = {
    plugins.lint = {
      enable = true;

      lazyLoad = {
        enable = true;
        settings = {
          event = ["BufReadPre" "BufNewFile"];
        };
      };

      lintersByFt = {
        nix = ["statix"];
        python = ["ruff"];
        lua = ["selene"];
        markdown = ["markdownlint"];
        sh = ["shellcheck"];
      };

      autoCmd = {
        event = ["BufWritePost" "BufReadPost"];
        callback.__raw = ''
          function()
            local ft = vim.bo.filetype
            local js_ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

            if vim.list_contains(js_ft, ft) then
              local root = vim.fs.find(
                { "biome.json", "biome.jsonc", ".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js" },
                { upward = true, path = vim.api.nvim_buf_get_name(0) }
              )[1]
              if not root then return end
              local filename = vim.fn.fnamemodify(root, ":t")
              if filename:find("biome") then
                require("lint").try_lint("biomejs")
              elseif filename:find("eslint") then
                require("lint").try_lint("eslint_d")
              end
            else
              require("lint").try_lint()
            end
          end
        '';
      };
    };

    extraPackages = [pkgs.statix];
  };
}
