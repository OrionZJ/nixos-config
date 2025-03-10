# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./clash.nix
  ] ++ [{ # functions & attrs
    # support fractional scaling for x11 gnome:
    # refer to https://nixos.wiki/wiki/Overlays#Overriding_a_package_inside_a_scope
    nixpkgs.overlays = [ (final: prev: {
      mutter = let
        mutter-x11-scaling = pkgs.fetchFromGitHub {
          owner = "puxplaying";
          repo = "mutter-x11-scaling";
          rev = "3a3a20ba7ae0af2c312373ebea9a33d912356217";
          hash = "sha256-aB4pc3qu9/1aYt2Mlj2lWcmW9Qva8BzLx4k4O7lgURk=";
        };
      in prev.mutter.overrideAttrs (old: {
        patches = (pkgs.lib.optionals (old ? patches) old.patches) ++ [
          "${mutter-x11-scaling}/x11-Add-support-for-fractional-scaling-using-Randr.patch"
        ];
      });
      gnome-control-center = let
        gnome-control-center-x11-scaling = pkgs.fetchFromGitHub {
          owner = "puxplaying";
          repo = "gnome-control-center-x11-scaling";
          rev = "12ce1fb886e46b96ae9dc278df19536d2093ca6d";
          hash = "sha256-6DkUzarvI/vZOSda0qmO65gwSvW2NC1gdx45gA21kB8=";
        };
      in prev.gnome-control-center.overrideAttrs (old: {
        patches = (pkgs.lib.optionals (old ? patches) old.patches) ++ [
          "${gnome-control-center-x11-scaling}/display-Support-UI-scaled-logical-monitor-mode.patch"
          "${gnome-control-center-x11-scaling}/display-Allow-fractional-scaling-to-be-enabled.patch"
        ];
      });
    }) ];

    # push the overrided mutter and gnome to my cachix
    cachix_packages = with pkgs; [mutter gnome-control-center];
  }] ;

  euphgh.sys.clash = {
    enable = true;
    configPath = ./dhh.yaml;
  };

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      default = "0";  # select second boot option (start from 0)
      efiSupport = true;
      useOSProber = true;
      # gfxmodeEfi = "1024x768";
    };
  };

  # config swapfile
  swapDevices = [ {
      device = "/var/swapfile";
      size = 1024 * 16;
    }
  ];

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "zh_CN.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
    inputMethod.enable = true;
    inputMethod.type = "ibus";
    inputMethod.ibus.engines = with pkgs.ibus-engines; [
      libpinyin
      rime
    ];
  };

  # 修复默认中文字体显示问题
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    noto-fonts-color-emoji
    noto-fonts-extra
    (nerdfonts.override {
      # The best developer fonts, see https://www.nerdfonts.com/
      fonts = [
        "Hack"
        "Meslo"
        "SourceCodePro"
        "FiraCode"
        "Terminus"
        "Iosevka"
        "Monoid"
        "FantasqueSansMono"
      ];
    })
    # refs to pkgs/data/fonts/roboto-mono/default.nix
    # (stdenv.mkDerivation {
    #   name = "my_fonts";
    #   srcs = [(fetchurl {
    #     url = "https://github.com/lxgw/LxgwWenKai/releases/download/v1.311/LXGWWenKai-Bold.ttf";
    #     sha256 = "16111vvjii2hmnigjb44rjj39k8hjawbvwrb3f2f1ph4hv5wnvkn";
    #   }) (fetchurl {
    #     url = "https://github.com/lxgw/LxgwWenKai/releases/download/v1.311/LXGWWenKai-Regular.ttf";
    #     sha256 = "103mvbpg51jvda265f29sjq17jj76dgwz6f1qdmv6d99bb8b6x7w";
    #   })];
    #   sourceRoot = "./";
    #   unpackCmd = ''
    #     ttfName=$(basename $(stripHash $curSrc))
    #     cp $curSrc ./$ttfName
    #   '';
    #   installPhase = ''
    #     mkdir -p $out/share/fonts/truetype
    #     cp -a *.ttf $out/share/fonts/truetype/
    #   '';
    # })
  ];
  # enable fontDir /run/current-system/sw/share/X11/fonts
  fonts.fontDir.enable = true;
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "DejaVu Sans Mono"
      "Noto Color Emoji"
      "Noto Emoji"
    ];
  };

  services.gpm.enable = true;

  hardware.xone.enable = true;

  # for x11 gesture
  services.touchegg.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = false;
  services.desktopManager.gnome.enable = true;

  #### Nvidia Stuff ####
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    # Make sure to use the correct Bus ID values for your system!
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = false;
  hardware.nvidia.powerManagement.finegrained = false;
  hardware.nvidia.open = false;
  hardware.nvidia.nvidiaSettings = true;

  # If you encounter the problem of booting to text mode you might try adding the Nvidia kernel module manually with this
  # boot.initrd.kernelModules = [ "nvidia" ];
  # boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  #disable nouveau
  boot.kernelParams = [ "modprobe.blacklist=nouveau" ];

  #Screen Tearing Issues
  hardware.nvidia.forceFullCompositionPipeline = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.root.hashedPassword = "$y$j9T$Dc0z5HJ3PYdhHA2kr4Esk1$vNplkes2gwg2yaCqhDzHc08O9ptUnZL8FMCA6pCvv1";
  users.users.hzj = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$lupZLAnLEjyWt3NzBd7oq1$x82mLRQkxHKNwp2gKp18rrxbMbUBvSqklRuqmnstBB9";
    extraGroups = [ "wheel" "docker" "libvirtd" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
      pkgs.wechat-uos
      pkgs.qq
      pkgs.termius
      pkgs.jetbrains.clion
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    tree
    pkgs.firefox
    pkgs.microsoft-edge
    pkgs.google-chrome
    pkgs.neofetch
    pkgs.fish
    pkgs.vscode
    pkgs.wpsoffice-cn
  ];

  environment.variables.EDITOR = "vim";


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #### Enable Docker #####
  virtualisation.docker.enable = true;
  # If you use the btrfs filesystem, you might need to set the storageDriver option
  virtualisation.docker.storageDriver = "btrfs";
  # Changing Docker Daemon's Data Root
  virtualisation.docker.daemon.settings = {
    data-root = "/home/hzj/DockerData";
    registry-mirrors = [
      "https://docker.hpcloud.cloud"
      "https://docker.m.daocloud.io"
      "https://docker.unsee.tech"
      "https://docker.1panel.live"
      "http://mirrors.ustc.edu.cn"
      "https://docker.chenby.cn"
      "http://mirror.azure.cn"
      "https://dockerpull.org"
      "https://dockerhub.icu"
      "https://hub.rat.dev"
    ];
  };
  #### Docker End ####

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion.

  nix.settings.substituters = [
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://cache.nixos.org/"
    "https://xieby1.cachix.org"
  ];

  networking.hosts = {
    # "140.82.114.4" = ["github.com"];
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
