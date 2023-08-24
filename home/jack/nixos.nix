{ pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];



  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.jack = {
    isNormalUser = true;
    home = "/home/jack";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    password = "jack";
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix)
  ];
}
