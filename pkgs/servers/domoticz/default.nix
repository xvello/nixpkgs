{ stdenv, fetchFromGitHub
, pkgconfig, git, cmake, makeWrapper
, python3, zlib, curl, boost170
, libusb,  openzwave }:

stdenv.mkDerivation rec {
  name = "domoticz-${version}";
  version = "4.10717";

  src = fetchFromGitHub {
    owner  = "domoticz";
    repo   = "domoticz";
    rev    = "${version}";
    sha256 = "1f93y7rpw2r1dsl4ajn317si4cq53qiiml6999swk5hv2nq3dmg2";
  };

  patches = [
    # Backported from development @ 8faa48d
    # Fix version computation and boost dependency check
    ./backport_cmake_fixes.patch
    # Linking issues to investigate further
    ./fix_linking.patch
  ];

  nativeBuildInputs = [ pkgconfig git cmake makeWrapper ];
  buildInputs = [ python3 zlib curl boost170 libusb openzwave];
  enableParallelBuilding = true;

  # This breaks version detection
  dontUseCmakeBuildDir = true;

  preConfigure = "export prefix=$out/share/domoticz";
  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=YES"
    "-DUSE_OPENSSL_STATIC=NO"
    "-DUSE_STATIC_BOOST=NO"
    "-DUSE_STATIC_OPENZWAVE=NO"
    "-DUSE_STATIC_LIBSTDCXX=NO"
    "-DUSE_BUILTIN_ZLIB=NO"
  ];

  postInstall = ''
    mkdir -p $out/bin
    mv $out/share/domoticz/domoticz $out/bin/
    wrapProgram $out/bin/domoticz \
      --add-flags "-noupdates -approot $out/share/domoticz"

    rm $out/share/domoticz/scripts/download_update.sh \
       $out/share/domoticz/scripts/update_domoticz    \
       $out/share/domoticz/scripts/restart_domoticz   \
       $out/share/domoticz/updatedomo
  '';

  ## Hack to speedup
  #buildPhase = ''
  #  make -t
  #  echo -e "#!/bin/sh\necho $LD_LIBRARY_PATH" > /build/source/domoticz
  #  chmod +x /build/source/domoticz
  #'';
  #installPhase = ''
  #  /nix/store/9ifxn9p05l98aq7ia04b0ndh8ffb8im4-cmake-3.14.5/bin/cmake -P cmake_install.cmake
  #  eval "$postInstall"
  #'';
  ## End hack

  meta = with stdenv.lib; {
    description = "A very light weight home automation system";
    longDescription = ''
      Domoticz is a very light weight home automation system that lets you monitor and configure
      miscellaneous devices, including lights, switches, various sensors/meters like temperature,
      rainfall, wind, ultraviolet (UV) radiation, electricity usage/production, gas consumption,
      water consumption and many more.
      Notifications/alerts can be sent to any mobile device.
    '';
    homepage = https://www.domoticz.com/;
    changelog = "https://github.com/domoticz/domoticz/blob/${version}/History.txt";
    license = licenses.gpl3;
    maintainers = [ maintainers.xvello ];
    platforms = platforms.all;
  };
}
