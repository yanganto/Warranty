{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        rust-overlay.follows = "rust-overlay";
      };
    };

    sui-flake = {
      url = "github:yanganto/sui/flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        rust-overlay.follows = "rust-overlay";
        crane.follows = "crane";
      };
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, sui-flake, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        currentSystem = if system == "dev" then builtins.currentSystem else system;
      in
      {
        devShells = {
          dev = sui-flake.devShells."${currentSystem}".slim;
          default = sui-flake.devShells."${system}".slim;
        };
      }
    );
}
