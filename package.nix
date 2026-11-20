{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  fontconfig,
  freetype,
  libxcb,
  libxkbcommon,
  wayland,
  libglvnd,
  vulkan-loader,
  libX11,
  libXcursor,
  libXi,
}:

let
  release = lib.importJSON ./release.json;
in
rustPlatform.buildRustPackage {
  pname = "ibis-office";
  inherit (release) version cargoHash;

  src = fetchFromGitHub {
    owner = "ibisjp";
    repo = "ibis-office";
    tag = "v${release.version}";
    fetchSubmodules = true;
    hash = release.sourceHash;
  };
  cargoBuildFlags = [
    "--package=ibis-office-app"
    "--bin=ibisOffice"
  ];
  # Upstream's scenario tests require a separate graphical test setup.
  doCheck = false;

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = [ fontconfig freetype libxcb libxkbcommon wayland ];

  env = {
    CARGO_PROFILE_RELEASE_INCREMENTAL = "false";
    CARGO_PROFILE_RELEASE_LTO = "false";
    IBIS_OFFICE_DIST = "1";
  };

  # The release tag still contains the previous version.txt. Match upstream Linux CI.
  postPatch = ''
    printf '%s\t%s\n' Windows '${release.version}' macOS '${release.version}' \
      wasm '${release.version}' Linux '${release.version}' > version.txt
  '';

  postInstall = ''
    install -Dm644 crates/ibis-office-app/linux/ibisoffice.desktop \
      "$out/share/applications/ibisoffice.desktop"
    install -Dm644 crates/ibis-office-shell/logo/png/ico/ibisOffice_icon_win_256px_transparent.png \
      "$out/share/icons/hicolor/256x256/apps/ibisoffice.png"
    install -Dm644 crates/ibis-formats/data/artborders/{OfficeOpenXML-WordprocessingMLArtBorders.zip,ECMA-NOTICE.txt} \
      -t "$out/share/ibisOffice/artborders"
    install -Dm644 LICENSE NOTICE COMMERCIAL-LICENSE.md \
      crates/ibis-office-render/fonts/carlito/OFL.txt -t "$out/share/doc/ibisOffice"
    install -Dm644 crates/ibis-office-app/linux/license.md \
      "$out/share/doc/ibisOffice/third-party-licenses.md"
  '';

  postFixup = ''
    # The MCP exporter finds itself by the executable's basename.
    mkdir -p "$out/libexec"
    mv "$out/bin/ibisOffice" "$out/libexec/ibisOffice"
    makeWrapper "$out/libexec/ibisOffice" "$out/bin/ibisOffice" --suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath [
      libglvnd
      vulkan-loader
      wayland
      libxkbcommon
      libX11
      libXcursor
      libXi
      libxcb
    ]}'
  '';

  meta = {
    description = "Editor for Word, Excel, and PowerPoint documents";
    homepage = "https://github.com/ibisjp/ibis-office";
    license = lib.licenses.agpl3Only;
    mainProgram = "ibisOffice";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
