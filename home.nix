{...}: {
  imports = [
    ./modules/home
  ];
  home.username = "xvantz";
  home.homeDirectory = "/home/xvantz";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
