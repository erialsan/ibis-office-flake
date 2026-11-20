{
  description = "Native Linux build of ibisOffice";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    {
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ibis-office = pkgs.callPackage ./package.nix { };
        in
        {
          inherit ibis-office;
          default = ibis-office;
        }
      );
    };
}
