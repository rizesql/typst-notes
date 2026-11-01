{
  description = "Course notes in Typst: page style, linked notes, named statements";

  inputs = {
    # Only for the Commit Mono build in shared/commit-mono-rizesql.
    dotfiles = {
      url = "github:rizesql/dotfiles-v2";
      flake = false;
    };
  };

  outputs =
    { dotfiles, ... }:
    let
      manifest = (fromTOML (builtins.readFile ./typst.toml)).package;
    in
    {
      lib.mkShell =
        {
          pkgs,
          name ? "notes",
          packages ? [ ],
        }:
        let
          # Typst resolves `@local/notes:0.1.0` to $TYPST_PACKAGE_PATH/local/notes/0.1.0.
          typstPackages = pkgs.runCommand "typst-packages" { } ''
            dir=$out/local/${manifest.name}/${manifest.version}
            mkdir -p $dir
            cp ${./typst.toml} $dir/typst.toml
            cp ${./lib.typ} $dir/lib.typ
          '';
        in
        pkgs.mkShell {
          inherit name;
          nativeBuildInputs = [ pkgs.typst ] ++ packages;

          TYPST_PACKAGE_PATH = "${typstPackages}";
          # Typst only scans system font dirs, not the Nix store. With system fonts off, the
          # PDF depends only on these and Typst's embedded fonts.
          TYPST_FONT_PATHS = builtins.concatStringsSep ":" [
            "${pkgs.geist-font}/share/fonts"
            "${pkgs.ibm-plex}/share/fonts"
            "${dotfiles}/shared/commit-mono-rizesql"
          ];
          TYPST_IGNORE_SYSTEM_FONTS = "true";
        };

      templates.default = {
        path = ./template;
        description = "A course: main.typ, concepts/ and notes/";
      };
    };
}
