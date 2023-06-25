---
title: Test Post
date: 2023-06-20
tags: test post
draft: false
---
# Markdown syntax guide

## Headers

# This is a Heading h1
## This is a Heading h2 
### This is a Heading h3
#### This is a heading h4
##### This is a heading h5
###### This is a Heading h6

## Emphasis

*This text will be italic*  
_This will also be italic_

**This text will be bold**  
__This will also be bold__

_You **can** combine them_

## Lists

### Unordered

* Item 1
* Item 2
* Item 2a
* Item 2b

### Ordered

1. Item 1
1. Item 2
1. Item 3
  1. Item 3a
  1. Item 3b

## Images

![This is an alt text.](https://markdownlivepreview.com/image/sample.png "This is a sample image.")

## Links

You may be using [Markdown Live Preview](https://markdownlivepreview.com/).

## Blockquotes

> Markdown is a lightweight markup language with plain-text-formatting syntax, created in 2004 by John Gruber with Aaron Swartz.
> - Test

## Blocks of code

```js
let message = 'Hello world';
alert(message);
```

## Inline code

This web site is not using `markedjs/marked`.

## This projects flake

```nix
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
        ${pkgs.nodePackages.live-server}/bin/live-server --port=5003  --no-browser --cors content
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
```