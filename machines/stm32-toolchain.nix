{ pkgs, stdenv, fetchurl, ncurses5, libiconv }:

stdenv.mkDerivation rec {
  pname = "stm32-toolchain";
  version = "1.0.0";

  buildInputs = [ncurses5 libiconv];

  openocdSrc = fetchurl {
    url = "https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.11.0-3/xpack-openocd-0.11.0-3-linux-arm64.tar.gz";
    sha256 = "lg5mKUbBOiJDwP+6oqblrSZIfLHPWKImWpfhGBk3oos=";
  };

  gccSrc = fetchurl {
    url = "https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-aarch64-linux.tar.bz2";
    sha256 = "9gW18jyomOm4tmW+IIUQpUpun90Ppb/JWSAC9udDEgg=";
  };

  unpackPhase = ''
    mkdir -p $out/.toolchain/STM32
    mkdir -p $out/.toolchain/tmp
    tar -xvf ${openocdSrc} -C $out/.toolchain/STM32/
    tar -xjvf ${gccSrc} -C $out/.toolchain/tmp/
    '';

  installPhase = ''
    cp -r $out/.toolchain/tmp/gcc-arm-none-eabi-10.3-2021.10/* $out/.toolchain/STM32/
    rm -rf $out/.toolchain/tmp

    find $out/.toolchain/STM32/ -type f -executable -exec patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux-aarch64.so.1 {} \;
    cp $out/.toolchain/STM32/xpack-openocd-0.11.0-3/libexec/* $out/.toolchain/STM32/bin/

    echo "export TOOLCHAIN_PATH=$out/.toolchain/STM32" > $out/setupSTM32Env.sh
    find $out/.toolchain/STM32/ -type f | while read bin; do
      if [[ $(file "$bin") == *'ELF'* ]]; then
        if [[ $(file "$bin") == *'executable'* ]]; then
          echo "Processing executable: $bin"
          patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux-aarch64.so.1 "$bin"
          patchelf --set-rpath "${stdenv.cc.cc}/lib:${pkgs.ncurses5}/lib:$out/.toolchain/STM32/bin:${stdenv.cc.cc.lib}/lib/" "$bin"
        elif [[ $(file "$bin") == *'shared object'* ]]; then
          echo "Processing shared library: $bin"
          patchelf --set-rpath "${stdenv.cc.cc}/lib:${pkgs.ncurses5}/lib" "$bin"
        fi
      fi
    done

    cp $out/.toolchain/STM32/xpack-openocd-0.11.0-3/bin/openocd $out/.toolchain/STM32/bin/openocd
    patchelf --set-rpath "${pkgs.libiconv}/lib:${stdenv.cc.cc}/lib:${pkgs.ncurses5}/lib:$out/.toolchain/STM32/bin:${stdenv.cc.cc.lib}/lib/:$out/.toolchain/STM32/xpack-openocd-0.11.0-3/libexec/" "$out/.toolchain/STM32/bin/openocd"

    '';
}