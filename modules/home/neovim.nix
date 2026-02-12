{
  pkgs,
  config,
  selfPath,
  ...
}: {
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${selfPath}/config/nvim";

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      nodePackages.markdownlint-cli
      nodePackages.tailwindcss
      nodePackages.svelte-language-server
      nodePackages.sass
      nodePackages.postcss
      selene
      lua-language-server
      stylua
    ];
  };
}
