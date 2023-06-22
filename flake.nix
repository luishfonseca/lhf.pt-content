{
  description = "lhf.pt website content";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { ... } @ inputs: inputs.utils.lib.eachDefaultSystem (system:
    let
      pkgs = import inputs.nixpkgs { inherit system; };

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
      apps.build-posts-index = mkApp buildPostsIndex;
      apps.serve = mkApp serve;
    });
}
