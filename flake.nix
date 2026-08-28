{
  description = "NixOS configuration flake";

  nixConfig = {
    accept-flake-config = true;
    warn-dirty = false;
    # Substituters/keys live in configuration.nix nix.settings (system-level).
    # john isn't a trusted user, so pushing them from here is rejected with a
    # warning and is redundant with the daemon already trusting them.
  };

  inputs = {
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pond = {
      url = "gitlab:Morgenkaff/flake-for-pond";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:patrickjaja/claude-desktop-extra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-cowork-service = {
      url = "github:patrickjaja/claude-cowork-service";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gnome-extensions-overlay.url = "path:./overlays/gnome-extensions";
  };

  outputs = {
    claude-cowork-service,
    claude-desktop,
    disko,
    gnome-extensions-overlay,
    home-manager,
    impermanence,
    lanzaboote,
    llm-agents,
    nix-vscode-extensions,
    nixpkgs,
    nixos-hardware,
    nur,
    plasma-manager,
    pond,
    sops-nix,
    self,
    stylix,
    ...
  } @ inputs: {
    nixosConfigurations = {
      nixos-framework = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./configuration.nix
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          nixos-hardware.nixosModules.framework-intel-core-ultra-series3
          claude-cowork-service.nixosModules.default
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          {
            nixpkgs.overlays = [
              nix-vscode-extensions.overlays.default
              nur.overlays.default
              pond.overlays.default
              gnome-extensions-overlay.overlays.default
            ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.user = ./home.nix;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.backupFileExtension = "backup";
            home-manager.overwriteBackup = true;
            home-manager.sharedModules = [
              plasma-manager.homeModules.plasma-manager
              inputs.sops-nix.homeModules.sops
            ];
          }
        ];
      };
    };
  };
}
