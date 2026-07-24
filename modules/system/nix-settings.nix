{
  config,
  pkgs,
  ...
}: {
  sops.secrets.github_nix.owner = "xvantz";

  nix.package = pkgs.lixPackageSets.stable.lix;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    extra-sandbox-paths = ["/run/nscd/socket"];
  };
  nix.extraOptions = ''
    !include ${config.sops.secrets.github_nix.path}
  '';
}
