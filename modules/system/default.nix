{...}: {
  imports = [
    ./boot.nix
    ./display.nix
    ./network.nix
    ./audio.nix
    ./portals.nix
    ./power.nix
    ./packages.nix
    ./virtualization.nix
    ./bluetooth.nix
    ./i18n.nix
    ./nix-settings.nix
    ./services.nix
  ];
}
