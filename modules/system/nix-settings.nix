{...}: {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    substituters = ["https://anyrun.cachix.org"];
    trusted-public-keys = ["anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="];
  };
}
