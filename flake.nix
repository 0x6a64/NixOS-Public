{
  description = "NixOS configuration flake";

  nixConfig = {
    warn-dirty = false;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secureboot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Vscode Extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Discord
    nixcord = {
      url = "github:FlameFlag/nixcord";
    };

    # NixOS Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {
    disko,
    home-manager,
    impermanence,
    lanzaboote,
    llm-agents,
    nix-cachyos-kernel,
    nix-flatpak,
    nix-vscode-extensions,
    nixcord,
    nixpkgs,
    nixos-hardware,
    nur,
    plasma-manager,
    sops-nix,
    self,
    stylix,
    zen-browser,
    ...
  } @ inputs: {
    nixosConfigurations = {
      nixos-framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./configuration.nix
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.framework-13-7040-amd
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          {
            nixpkgs.overlays = [
              nix-cachyos-kernel.overlays.default
              nix-vscode-extensions.overlays.default
              nur.overlays.default
            ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.user = ./home.nix;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.backupFileExtension = "backup";
            home-manager.overwriteBackup = true; # This is the key option!
            home-manager.sharedModules = [
              #plasma-manager.homeModules.plasma-manager
              inputs.nixcord.homeModules.nixcord
              inputs.sops-nix.homeModules.sops
            ];
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };
}
