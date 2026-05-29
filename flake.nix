{
  description = "Minimal Flake with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun.url = "github:anyrun-org/anyrun";

    coolcontrol.url = "github:xvantz/coolcontrol";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    selfPath = "/home/xvantz/.dotfiles";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-unstable = pkgs;
    customPkgs = import ./customPkgs/default.nix pkgs;
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs pkgs-unstable customPkgs selfPath;};
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        inputs.coolcontrol.nixosModules.default
        inputs.hermes-agent.nixosModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs pkgs-unstable customPkgs selfPath;
          };
          home-manager.users.xvantz = {
            disabledModules = ["programs/anyrun.nix"];

            imports = [
              inputs.anyrun.homeManagerModules.default
              ./home.nix
            ];
          };
        }
      ];
    };
  };
}
