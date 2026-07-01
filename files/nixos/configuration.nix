{ config, pkgs, ... }:

{
 imports =
    [
      ./hardware-configuration.nix
    ];


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  nixpkgs.config = {allowUnfree = true; };

  boot.kernelPackages = pkgs.linuxPackages_zen;

  networking.hostName = "nixos"; 

  networking.networkmanager.enable = true;
  networking.wireguard.enable = true;

  security.sudo.wheelNeedsPassword = false;

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

  services.greetd = {
  enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
        user = "greeter";
      };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.intone-mono
  ];

  hardware.graphics = {
  enable = true;
  enable32Bit = true;
  };


  users.users."quasar" = {
    isNormalUser = true;
    description = "qmoore56";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [

    ];
  };


  programs.zsh.enable = true;
  programs.starship.enable = true;
  programs.neovim.enable = true;

  services.flatpak.enable = true;
  services.mullvad-vpn.enable = true;

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";
  environment.variables.PAGER = "moor";



  programs.steam = {
      enable = true;
  };

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
     protonup-qt
     wpaperd
     gcc
     gnumake
     gimp
     btop
     rofi
     flatpak
     gamemode
     tuigreet
     mesa
     moor
     vulkan-tools
     crosspipe
     fastfetch #larp
  ];


  system.stateVersion = "26.05"; 

}
