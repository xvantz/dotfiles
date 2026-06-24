{...}: {
  imports = [
    ./modules/home
  ];

  sops.age.keyFile = "/home/xvantz/.config/sops/age/keys.txt";
  sops.defaultSopsFile = /home/xvantz/.dotfiles/secrets.yaml;

  home.username = "xvantz";
  home.homeDirectory = "/home/xvantz";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
