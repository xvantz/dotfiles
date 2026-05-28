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

      input = {
        enable = true;
        icon = " ";
        icon_hl = "SnacksInputIcon";
        icon_pos = "left";
        prompt_pos = "title";
        win = {style = "input";};
        expand = true;
      };

      lazygit = {
        enable = true;
        configure = true;
        config = {
          os = {editPreset = "nvim-remote";};
          gui = {
            nerdFontsVersion = "3";
          };
        };
        theme = {
          activeBorderColor = {
            fg = "MatchParen";
            bold = true;
          };
          cherryPickedCommitBgColor = {fg = "Identifier";};
          cherryPickedCommitFgColor = {fg = "Function";};
          defaultFgColor = {fg = "Normal";};
          inactiveBorderColor = {fg = "FloatBorder";};
          optionsTextColor = {fg = "Function";};
          searchingActiveBorderColor = {
            fg = "MatchParen";
            bold = true;
          };
          selectedLineBgColor = {bg = "Visual";};
          unstagedChangesColor = {fg = "DiagnosticError";};
        };
        win = {
          style = "lazygit";
        };
      };

      dashboard = {
        enable = true;
        width = 60;
        pane_gap = 4;
        autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

        preset = {
          keys = [
            {
              icon = " ";
              key = "f";
              desc = "Find File";
              action = ":lua Snacks.dashboard.pick('files')";
            }
            {
              icon = " ";
              key = "n";
              desc = "New File";
              action = ":ene | startinsert";
            }
            {
              icon = " ";
              key = "g";
              desc = "Find Text";
              action = ":lua Snacks.dashboard.pick('live_grep')";
            }
            {
              icon = " ";
              key = "r";
              desc = "Recent Files";
              action = ":lua Snacks.dashboard.pick('oldfiles')";
            }
            {
              icon = " ";
              key = "c";
              desc = "Config";
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})";
            }
            {
              icon = " ";
              key = "s";
              desc = "Restore Session";
              section = "session";
            }
            {
              icon = "󰒲 ";
              key = "L";
              desc = "Lazy";
              action = ":Lazy";
              enabled.__raw = "package.loaded.lazy ~= nil";
            }
            {
              icon = " ";
              key = "q";
              desc = "Quit";
              action = ":qa";
            }
          ];
          header = ''
            ██╗  ██╗██╗   ██╗ █████╗ ███╗   ██╗████████╗███████╗
            ╚██╗██╔╝██║   ██║██╔══██╗████╗  ██║╚══██╔══╝╚══███╔╝
             ╚███╔╝ ██║   ██║███████║██╔██╗ ██║   ██║     ███╔╝
             ██╔██╗ ╚██╗ ██╔╝██╔══██║██║╚██╗██║   ██║    ███╔╝
            ██╔╝ ██╗ ╚████╔╝ ██║  ██║██║ ╚████║   ██║   ███████╗
            ╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
                          ✦  x v a n t z . n v i m  ✦
          '';
        };

        formats = {
          icon.__raw = ''
            function(item)
              if item.file and (item.icon == "file" or item.icon == "directory") then
                return Snacks.dashboard.icon(item.file, item.icon)
              end
              return { item.icon, width = 2, hl = "icon" }
            end
          '';
          file.__raw = ''
            function(item, ctx)
              local fname = vim.fn.fnamemodify(item.file, ":~")
              fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
              if #fname > ctx.width then
                local dir = vim.fn.fnamemodify(fname, ":h")
                local file = vim.fn.fnamemodify(fname, ":t")
                if dir and file then
                  file = file:sub(-(ctx.width - #dir - 2))
                  fname = dir .. "/…" .. file
                end
              end
              local dir, file = fname:match("^(.*)/(.+)$")
              return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
            end
          '';
        };

        sections = [
          {section = "header";}
          {
            section = "keys";
            gap = 1;
            padding = 1;
          }
          {section = "startup";}
        ];
      };
    };
  };
}
