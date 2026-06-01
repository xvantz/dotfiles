{
  description = "Minimal Flake with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    coolcontrol.url = "github:xvantz/coolcontrol";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      config.permittedInsecurePackages = ["openssl-1.1.1w"];
    };

    customPkgs = import ./customPkgs/default.nix pkgs;

    sharedArgs = {inherit inputs pkgs customPkgs selfPath;};
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = sharedArgs;
      modules = [
        ./configuration.nix
        inputs.coolcontrol.nixosModules.default
        inputs.hermes-agent.nixosModules.default
      ];
    };

    homeConfigurations.xvantz = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home.nix
        inputs.anyrun.homeManagerModules.default
        inputs.sops-nix.homeManagerModules.sops
      ];
      extraSpecialArgs = sharedArgs;
    };
  };
}
