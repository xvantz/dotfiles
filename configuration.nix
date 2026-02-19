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

  fileSystems."/".options = ["compress=zstd" "space_cache=v2" "discard=async" "commit=15"];
  fileSystems."/home".options = ["compress=zstd" "space_cache=v2" "discard=async" "commit=15"];
  fileSystems."/nix".options = ["compress=zstd" "space_cache=v2" "discard=async" "commit=15"];
  fileSystems."/var/log".options = ["compress=zstd" "space_cache=v2" "discard=async" "commit=15"];

  system.stateVersion = "25.11";
}
