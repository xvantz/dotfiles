{inputs, ...}: {
  imports = [
    inputs.nixvim.homeModules.nixvim

    ./core.nix
    ./keymaps.nix
    ./autocmds.nix
    ./plugins
  ];
}
