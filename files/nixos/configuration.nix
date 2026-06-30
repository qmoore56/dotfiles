{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  nixpkgs.config = {allowUnfree = true; };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; 

  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };


  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };


    fonts.packages = with pkgs; [
      nerd-fonts.intone-mono
    ];
 

  users.users."quiche" = {
    isNormalUser = true;
    description = "quiche";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  programs.zsh.enable = true;
  programs.starship.enable = true;
  programs.neovim.enable = true;
  programs.steam.enable = true;

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };


  environment.systemPackages = with pkgs; [
     neovim
     firefox
     kitty
     git
     starship
     wl-clipboard
     eza
     lf
     steam
     grim
     nixd
     mullvad
     waybar
     pavucontrol
     networkmanager
     flatpak
     rofi 
     fastfetch #larp
  ];


  system.stateVersion = "26.05"; 

}
