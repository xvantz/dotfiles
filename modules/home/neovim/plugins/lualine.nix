{...}: {
  programs.nixvim.plugins.lualine = {
    enable = true;
    lazy = [{event = "VeryLazy";}];

    settings = {
      options = {
        theme = "tokyonight";
        component_separators = {
          left = "";
          right = "";
        };
        section_separators = {
          left = "";
          right = "";
        };
        disabled_filetypes = ["dashboard" "lazy"];
        globalstatus = true;
      };

      sections = {
        lualine_a = ["mode"];
        lualine_b = [
          "branch"
          "diff"
          {
            __unkeyed-1 = "diagnostics";

            sources = ["nvim_diagnostic"];
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = "󰌶 ";
            };
          }
        ];
        lualine_c = [
          {
            __unkeyed-1 = "filename";

            path = 1;
            symbols = {
              modified = "󰆓";
              readonly = "";
              unnamed = "[No Name]";
            };
          }
        ];
        lualine_x = [
          {
            __unkeyed-1.__raw = ''
              function()
                local ok, blink = pcall(require, "blink.cmp")
                if ok and blink.is_visible then
                  return blink.is_visible() and " 󰏔 " or ""
                end
                return ""
              end
            '';
            color = {fg = "#89b4fa";};
          }
          {
            __unkeyed-1.__raw = ''
              function()
                if vim.lsp.status then
                  local status = vim.lsp.status()
                  if status and #status > 0 then
                    return " 󰩈 " .. (status[1].message or "")
                  end
                end
                return ""
              end
            '';
          }
          {
            __unkeyed-1.__raw = ''
              function()
                local ok, ts = pcall(require, "nvim-treesitter.parsers")
                if not ok then return "" end
                local parser = ts.get_parser(vim.api.nvim_get_current_buf())
                return parser and " 󰔱 " or ""
              end
            '';
            color = {fg = "#94e2d5";};
          }
          "encoding"
          "fileformat"
          "filetype"
        ];
        lualine_y = ["progress" "location"];
        lualine_z = [{__unkeyed-1.__raw = "function() return os.date('%H:%M') end";}];
      };

      inactive_sections = {
        lualine_c = [{filename = {path = 1;};}];
        lualine_x = ["location"];
      };

      extensions = ["lazy"];
    };
  };
}
