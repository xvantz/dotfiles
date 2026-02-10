{config, ...}: {
  imports = [
    ./modules/home
  ];
  home.username = "xvantz";
  home.homeDirectory = "/home/xvantz";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/xvantz/.dotfiles/config/nvim";
}
