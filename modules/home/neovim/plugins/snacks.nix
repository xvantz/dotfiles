{...}: {
  programs.nixvim.plugins.snacks = {
    enable = true;

    settings = {
      bigfile.enabled = true;
      statuscolumn.enabled = true;
      words.enabled = true;
      image.enabled = true;
      scroll.enabled = true;

      picker = {
        enabled = true;
        ui_select = true;
      };

      terminal = {
        win = {style = "terminal";};
      };

      notifier = {
        enabled = true;
        timeout = 3000;
        width = {
          min = 40;
          max = 0.4;
        };
        height = {
          min = 1;
          max = 0.6;
        };
        margin = {
          top = 0;
          right = 1;
          bottom = 0;
        };
        padding = true;
        sort = ["level" "added"];
        icons = {
          error = " ";
          warn = " ";
          info = " ";
          debug = " ";
          trace = " ";
        };
      };

      indent = {
        enable = true;
        priority = 1;
        char = "│";
        only_scope = false;
        only_current = false;
        hl = "SnacksIndent";

        animate = {
          enabled.__raw = "vim.fn.has('nvim-0.10') == 1";
          style = "out";
          easing = "linear";
          duration = {
            step = 20;
            total = 500;
          };
        };

        scope = {
          enabled = true;
          priority = 200;
          char = "│";
          underline = false;
          only_current = false;
          hl = "SnacksIndentScope";
        };

        chunk = {
          enabled = false;
          only_current = false;
          priority = 200;
          hl = "SnacksIndentChunk";
          char = {
            corner_top = "╭";
            corner_bottom = "╰";
            horizontal = "─";
            vertical = "│";
            arrow = ">";
          };
        };

        filter.__raw = ''
          function(buf, win)
            return vim.g.snacks_indent ~= false
               and vim.b[buf].snacks_indent ~= false
               and vim.bo[buf].buftype == ""
          end
        '';
      };
    };
  };
}
