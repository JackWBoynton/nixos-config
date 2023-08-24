{ config, pkgs, lib, ... }:

let

  STM32Toolchain = pkgs.callPackage ./stm32-toolchain.nix {
    inherit (pkgs) stdenv fetchurl ncurses5 libiconv;
  };
in {
  imports = [
    ../modules/vmware-guest.nix
    ./vm-shared.nix
  ];

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  # setup STM32 toolchain
  environment.systemPackages = [
    # vscode
    pkgs.krb5
    pkgs.cmake
    pkgs.ncurses5
    pkgs.libftdi
    pkgs.libusb1
    pkgs.ninja
    pkgs.gdb
    pkgs.libiconv
    STM32Toolchain
  ];

  environment.variables = {
    TOOLCHAIN_PATH = "${STM32Toolchain}/.toolchain/STM32/bin/";
  };

}
