{ pkgs }:

let
  inherit (pkgs.stdenv.hostPlatform) system isLinux isDarwin;

  pname = "zen";
  version = "1.22.1b";

  meta = {
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };

  url = "https://github.com/zen-browser/desktop/releases/download/${version}/";

  release =
    {
      x86_64-linux = {
        url = url + "zen-x86_64.AppImage";
        hash = "sha256-tH/y/cAClE9zcq145V35D1/KQv6rTleM4jblh/w7418=";
      };
      aarch64-linux = {
        url = url + "zen-aarch64.AppImage";
        hash = "sha256-AThGPngTkQ2r8rgPvg3l4Gsppc3oRTFBDDViqw2IcEk=";
      };
      aarch64-darwin = {
        url = url + "zen.macos-universal.dmg";
        hash = "sha256-OQSmejhRsaYZ4tP6enCDWh1+Q2etMJMcz5tNIykq+ZA=";
      };
    }
    .${system} or (throw "Zen is unsupported on ${system}");

  src = pkgs.fetchurl release;
in
if isLinux then
  pkgs.appimageTools.wrapType2 {
    inherit
      pname
      version
      src
      meta
      ;

    extraPkgs = pkgs: with pkgs; [ ffmpeg_8 ];

    extraInstallCommands =
      let
        contents = pkgs.appimageTools.extract { inherit pname version src; };
      in
      ''
        install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace 'Exec=AppRun' 'Exec=${pname}'
        cp -r ${contents}/usr/share/icons $out/share
      '';
  }
else if isDarwin then
  pkgs.stdenvNoCC.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p "$out/Applications"
      cp -R *.app "$out/Applications/"
    '';

  }
else
  throw "Zen is unsupported on ${system}"
