{
  description = "Minimal Flake with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    coolcontrol.url = "github:xvantz/coolcontrol";

    sync-agent.url = "git+http://localhost:2000/xvantz/sync-agent.git";

    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.7.1";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pm.url = "git+https://git.827482.xyz/xvantz/pm.git";
    navidrome-collector.url = "git+http://git.827482.xyz/xvantz/navidrome-collector.git";
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    selfPath = "/home/xvantz/.dotfiles";

    makePkgs = src: extConfig:
      import src {
        inherit system;
        config =
          {
            allowUnfree = true;
            permittedInsecurePackages = ["openssl-1.1.1w" "electron-39.8.10" "pnpm-10.29.2"];
          }
          // extConfig;

        overlays = [
          (final: prev: {
            inherit
              (prev.lixPackageSets.stable)
              nix-eval-jobs
              nix-fast-build
              nix-direnv
              ;
            sync-agent = inputs.sync-agent.packages.${system}.default;
          })
          (import ./customPkgs/default.nix)
        ];
      };

    nixosPkgs = makePkgs nixpkgs {};
    homePkgs = makePkgs home-manager.inputs.nixpkgs {};

    sharedArgs = {inherit inputs selfPath;};
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = sharedArgs;
      modules = [
        {nixpkgs.pkgs = nixosPkgs;}
        ./configuration.nix
        inputs.coolcontrol.nixosModules.default
        inputs.sync-agent.nixosModules.default
        inputs.hermes-agent.nixosModules.default
        inputs.pm.nixosModules.default
        inputs.navidrome-collector.nixosModules.default
      ];
    };

    homeConfigurations.xvantz = home-manager.lib.homeManagerConfiguration {
      pkgs = homePkgs;
      modules = [
        ./home.nix
        inputs.sops-nix.homeManagerModules.sops
      ];
      extraSpecialArgs = sharedArgs;
    };
  };
}
