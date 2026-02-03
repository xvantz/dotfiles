{ config, pkgs, ... }:

{
  home.username = "xvantz";
  home.homeDirectory = "/home/xvantz";

  home.stateVersion = "25.11"; 

  home.packages = with pkgs; [
    neohtop
  ];

  programs.home-manager.enable = true;
  xdg.configFile."nvim".source = ./config/nvim;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/.dotfiles#nixos";
    };
  };
}
