{...}: {
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      vtsls.enable = true;
      lua_ls.enable = true;
      gopls.enable = true;
      rust_analyzer.enable = true;
      zls.enable = true;
      svelte.enable = true;
      html.enable = true;
      cssls.enable = true;
      marksman.enable = true;
      csharp_ls.enable = true;
      tailwindcss.enable = true;
    };
  };
}
