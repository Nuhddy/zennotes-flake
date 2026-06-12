{
  description = "ZenNotes with CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};

    pname = "zennotes";
    version = "2.2.0";

    src = pkgs.fetchurl {
      url = "https://github.com/ZenNotes/zennotes/releases/download/v${version}/ZenNotes-${version}-linux-x86_64.AppImage";
      sha256 = "sha256-9/amexk9rZlhs4RKndshO6hmRnmZV0t/e7qv9GWJVyI=";
    };

    wrapped = pkgs.appimageTools.wrapType2 {inherit pname version src;};

    extracted = pkgs.appimageTools.extractType2 {inherit pname version src;};

    desktopItem = pkgs.makeDesktopItem {
      name = "zennotes";
      desktopName = "ZenNotes";
      genericName = "ZenNotes GUI app";
      exec = "zennotes";
      categories = ["Office"];
    };

    zennotes = pkgs.symlinkJoin {
      name = "zennotes";
      paths = [wrapped desktopItem];
    };

    zennotesWithCli = pkgs.symlinkJoin {
      name = "zennotes-with-cli";
      paths = [wrapped desktopItem];

      nativeBuildInputs = [pkgs.makeWrapper];

      postBuild = ''
        mkdir -p $out/share/zennotes
        cp -r ${extracted}/resources $out/share/zennotes/

        mkdir -p $out/bin
        makeWrapper $out/bin/zennotes $out/bin/zen-cli \
          --set ELECTRON_RUN_AS_NODE 1 \
          --add-flags "$out/share/zennotes/resources/cli.js"
      '';
    };
  in {
    packages.${system} = {
      inherit zennotes zennotesWithCli;
      default = zennotes;
    };

    apps.${system} = {
      zennotes = {
        type = "app";
        program = "${zennotes}/bin/zennotes";
      };
      zen-cli = {
        type = "app";
        program = "${zennotesWithCli}/bin/zen-cli";
      };
    };
  };
}
