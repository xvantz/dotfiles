{...}: {
  programs.nixvim.plugins.render-markdown = {
    enable = true;

    lazyLoad = {
      enable = true;
      settings = {
        ft = "markdown";
      };
    };

    luaConfig = {
      content = ''
        vim.keymap.set("n", "<leader>rm", "<cmd>RenderMarkdown toggle<CR>", { desc = "Toggle Markdown Preview" })
      '';
    };
  };
}
