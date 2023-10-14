let
  pkgs = (builtins.getFlake "github:yorickvp/esp-idf.nix/main").legacyPackages.${builtins.currentSystem};
  inherit (pkgs) esp-idf esptool;

  python = pkgs.python3.withPackages (p: with p; [ pyusb ]);

in pkgs.stdenvNoCC.mkDerivation rec {
  pname = "clife-mch2022.bin";
  src = builtins.filterSource (path: type: !(builtins.elem path [
    "build"
    "esp-idf"
  ])) ./.;
  version = "0.1";
  buildInputs = with pkgs; [ cmake esp-idf ninja which ];

  IDF_PATH = "${esp-idf}";
  IDF_TOOLS_PATH = "${esp-idf}/tool";
  # stdenvNoCC is setting $AR to an empty string, confusing cmake
  AR = "xtensa-esp32-elf-ar";

  phases = "unpackPhase buildPhase installPhase fixupPhase";

  dontStrip = true;

  buildPhase = ''
    source $IDF_PATH/export.sh
    idf.py fullclean
    idf.py build
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv build/main.bin $out
    cat >$out/bin/flash << EOF
    ${python} ${tools/webusb_push.py} "Colored Game of Life" $out/main.bin --run
    EOF
  '';

  shellHook = ''
    export IDF_TOOLS_PATH=$IDF_PATH/tool
    source $IDF_PATH/export.sh
  '';
}
