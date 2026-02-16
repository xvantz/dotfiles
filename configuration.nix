{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.dms.nixosModules.greeter
    ./modules/system
  ];

  users.users.xvantz = {
    isNormalUser = true;
    description = "Ivan R.";
    extraGroups = ["networkmanager" "wheel" "video"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  system.stateVersion = "25.11";
}
