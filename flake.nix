{
  description = "lhf.pt website content";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";

    utils.url = "github:numtide/flake-utils";

    nix-filter.url = "github:numtide/nix-filter";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
      inputs.rust-overlay.follows = "rust-overlay";
    };
  };

  outputs = { ... } @ inputs: inputs.utils.lib.eachDefaultSystem (system:
    let
      pkgs = import inputs.nixpkgs { inherit system; overlays = [ inputs.rust-overlay.overlays.default ]; };

      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" ];
      };

      crane = (inputs.crane.mkLib pkgs).overrideToolchain rust;

      deps = crane.buildDepsOnly {
        src = inputs.nix-filter.lib.filter {
          root = ./indexer;
          include = [ "Cargo.toml" "Cargo.lock" ];
        };
      };

      indexer = crane.buildPackage {
        cargoArtifacts = deps;
        src = inputs.nix-filter.lib.filter {
          root = ./indexer;
          include = [ "Cargo.toml" "Cargo.lock" "src" ];
        };
      };

      buildPostsIndex = pkgs.writeScript "build-posts-index" ''
        ${pkgs.tree}/bin/tree content/posts -J > content/posts.json
      '';

      serve = pkgs.writeScript "serve" ''
        ${pkgs.nodePackages.serve}/bin/serve content -l 5003 -n
      '';

      mkApp = run: {
        type = "app";
        program = "${run}";
      };
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [ rust indexer ];
      };

      apps.build-posts-index = mkApp buildPostsIndex;
      apps.serve = mkApp serve;
    });
}
