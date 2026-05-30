{...}: {
  imports = [
    ./modules/home
  ];
  disabledModules = ["programs/anyrun.nix"];
  home.username = "xvantz";
  home.homeDirectory = "/home/xvantz";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
