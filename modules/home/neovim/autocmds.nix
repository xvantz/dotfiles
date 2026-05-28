{...}: {
  programs.nixvim = {
    autoCmd = [
      {
        event = ["TextYankPost"];
        group = "Core";
        callback.__raw = "function() vim.highlight.on_yank() end";
        desc = "Highlight yanked text";
      }
      {
        event = ["BufWritePre"];
        group = "Core";
        callback.__raw = "function() local ok, conform = pcall(require, 'conform'); if ok then conform.format({ lsp_fallback = true, timeout_ms = 2000 }) end end";
        desc = "Format buffer on save";
      }
    ];

    extraConfigVim = ''
      augroup Core
        autocmd!
      augroup END
    '';

    extraConfigLua = ''
      local function is_git_conflicted_file(filepath)
        local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if not git_root or git_root == "" or git_root:match("^fatal:") then return false end
        local abs = vim.fn.fnamemodify(filepath, ":p")
        if not abs:find(git_root, 1, true) then return false end
        local relpath = abs:sub(#git_root + 2)
        local cmd = string.format("cd %s && git diff --name-only --diff-filter=U -- %s", vim.fn.shellescape(git_root), vim.fn.shellescape(relpath))
        local result = vim.fn.systemlist(cmd)
        return #result > 0 and result[1] ~= ""
      end

      vim.api.nvim_create_autocmd("BufReadPost", {
        group = "Core",
        callback = function(args)
          local bufnr = args.buf
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name == "" or vim.bo[bufnr].buftype ~= "" then return end
          if not is_git_conflicted_file(name) then return end
          vim.schedule(function()
            if package.loaded["diffview"] or pcall(require, "diffview") then
              vim.cmd("DiffviewOpen")
            end
          end)
        end,
      })
    '';
  };
}
