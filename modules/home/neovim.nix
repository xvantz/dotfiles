{
  pkgs,
  config,
  ...
}: {
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/nvim";

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      nodePackages.markdownlint-cli
      nodePackages.tailwindcss
      nodePackages.svelte-language-server
      nodePackages.sass
      nodePackages.postcss
      nodePackages.pnpm
    ];
  };
}
