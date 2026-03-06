{
  lib,
  cmake,
  openssl,
  zlib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ixwebsocket";
  version = "11.4.6";

  src = fetchFromGitHub {
    owner = "machinezone";
    repo = "IXWebSocket";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-ZZ6y4qLgd57xQ3otrWquqI6ufc2W6dbvoh7KNXqgvSA=";
  };

  nativeBuildInputs = [
    cmake
    openssl
    zlib
  ];

  cmakeFlags = [
    "-DUSE_TLS=1"
  ];

  meta = {
    description = "Websocket and http client and server library, with TLS support and very few dependencies";
    homepage = "https://github.com/machinezone/IXWebSocket";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ videl ];
  };
})
