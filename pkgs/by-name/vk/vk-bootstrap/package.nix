{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  vulkan-headers,
  glfw,
  catch2_3,
}:

stdenv.mkDerivation rec {
  pname = "vk-bootstrap";
  version = "1.4.313";

  src = fetchFromGitHub {
    owner = "charles-lunarg";
    repo = "vk-bootstrap";
    rev = "v${version}";
    hash = "sha256-IMqAuJ+zdAaEYdHLAzznz8Cv0ox+tjrgacpfltPWI+M=";
  };

  # sourceRoot = "${src.name}";

  patches = [
    ./common.patch
  ];

  postPatch = ''
    # Upstream uses cmake FetchContent to resolve glfw and catch2
    # needed for examples and tests
    sed -i 's=add_subdirectory(ext)==g' CMakeLists.txt
  '';

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    vulkan-headers
    glfw
    catch2_3
  ];

  cmakeFlags = [
    "-DVK_BOOTSTRAP_VULKAN_HEADER_DIR=${vulkan-headers}/include"
    "-DCatch2_SOURCE_DIR=${catch2_3}/lib/cmake/Catch2/"
  ];

  installPhase = ''
    mkdir -p $out/{lib,include}

    cp libvk-bootstrap.a $out/lib/

    cp $src/src/VkBootstrap.h $out/include/
    cp $src/src/VkBootstrapDispatch.h $out/include/
  '';

  meta = with lib; {
    description = "Vulkan Bootstrapping Library";
    license = licenses.mit;
    homepage = "https://github.com/charles-lunarg/vk-bootstrap";
    maintainers = with maintainers; [ shamilton ];
    platforms = platforms.all;
  };
}
