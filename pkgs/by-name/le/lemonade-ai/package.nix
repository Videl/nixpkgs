{
  lib,
  cmake,
  nlohmann_json,
  openssl,
  ixwebsocket,
  curl,
  makeWrapper,
  llama-cpp-vulkan,
  llama-cpp-rocm,
  llama-cpp,
  whisper-cpp,
  ninja,
  zstd,
  pkg-config,
  cli11,
  httplib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  buildNpmPackage,
}:
let
  httplib-src = fetchFromGitHub {
    owner = "yhirose";
    repo = "cpp-httplib";
    rev = "v0.26.0";
    hash = "sha256-+VPebnFMGNyChM20q4Z+kVOyI/qDLQjRsaGS0vo8kDM=";
  };

  httplib-local = stdenv.mkDerivation {
    pname = "cpp-httplib";
    version = "0.26.0";
    src = httplib-src;
    nativeBuildInputs = [ cmake ];
    # This library is header-only, but CMake makes it a proper target
  };

  version = "9.4.1";

  src = fetchFromGitHub {
    owner = "lemonade-sdk";
    repo = "lemonade";
    rev = "v${version}";
    sha256 = "sha256-kUiibMFXyrUDaxw8X9VKxNuJ2FEfSTbWdB3fYQGfCio=";
  };

  web-app = buildNpmPackage (finalAttrs: {
    pname = "web-app";
    inherit version src;
    sourceRoot = "${src.name}/src/web-app";

    npmDepsHash = "sha256-d9ZzcpolixarWYZjruvpGlDCTnRXFnh/LljTLXngDmY=";
    postPatch = ''
      cp ${./web-app.package-lock.json} package-lock.json
    '';
    postInstall = ''
      mkdir $out/resources
      cp -r dist/renderer/ $out/resources/web-app/
    '';
  });

in
stdenv.mkDerivation (finalAttrs: {
  pname = "lemonade-ai";

  inherit version src;

  nativeBuildInputs = [
    cmake
    nlohmann_json
    curl
    cli11
    makeWrapper
    zstd
    pkg-config
    ninja
    ixwebsocket
  ];

  patches = [
    ./cmake.patch
  ];

  buildInputs = [
    curl
    httplib
    nlohmann_json
    openssl
  ];

  cmakeFlags = [
    "-DUSE_SYSTEM_HTTPLIB=OFF" # Force CMake to use the Nix-provided version
    "-DUSE_SYSTEM_JSON=ON"
    "-DUSE_SYSTEM_CLI11=ON"
    "-DUSE_SYSTEM_CURL=ON"
    "-DUSE_SYSTEM_ZSTD=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_SOURCE_DIR_HTTPLIB=${httplib-src}"
  ];

  env = {
    NIX_LDFLAGS = "-lssl -lcrypto";
  };

  postInstall = ''
    mkdir -p $out/bin/resources/web-app
    cp -r $src/src/cpp/resources/* $out/bin/resources
    chmod -R +w $out/bin/resources/
    cp -r ${web-app}/resources/web-app/* $out/bin/resources/web-app/

    wrapProgram $out/bin/lemonade-router \
      --set LEMONADE_LLAMACPP_VULKAN_BIN "${llama-cpp-vulkan}/bin/llama-server" \
      --set LEMONADE_LLAMACPP_ROCM_BIN "${llama-cpp-rocm}/bin/llama-server" \
      --set LEMONADE_LLAMACPP_CPU_BIN "${llama-cpp}/bin/llama-server" \
      --set LEMONADE_WHISPERCPP_CPU_BIN "${whisper-cpp}/bin/whisper-cpp-server" \
      --set LEMONADE_WHISPERCPP_VULKAN_BIN "${whisper-cpp.override { cudaSupport = false; }}/bin/whisper-cpp-server"
  '';

  meta = {
    description = "Lemonade helps users discover and run local AI apps by serving optimized LLMs right from their own GPUs and NPUs.";
    homepage = "https://github.com/lemonade-sdk/lemonade/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ videl ];
    mainProgram = "lemonade-server";
  };
})
