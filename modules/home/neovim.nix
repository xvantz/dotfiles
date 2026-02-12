{
  pkgs,
  config,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
in {
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/nvim";

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      nodePackages.markdownlint-cli
      nodePackages.tailwindcss
      nodePackages.svelte-language-server
      nodePackages.sass
      nodePackages.postcss
    ];
  };
}
