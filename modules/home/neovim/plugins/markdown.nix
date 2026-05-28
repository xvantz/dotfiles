{...}: {
  programs.nixvim.plugins.render-markdown = {
    enable = true;

    lazy = [{ft = "markdown";}];

    keys = [
      {
        mode = "n";
        key = "<leader>rm";
        action = "<cmd>RenderMarkdown toggle<CR>";
        options.desc = "Toggle Markdown Preview";
      }
    ];
  };
}
