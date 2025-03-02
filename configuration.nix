# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./clash.nix
  ];

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
    inputMethod.type = "fcitx5";
    inputMethod.fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-qt
      fcitx5-chinese-addons
      fcitx5-nord
    ];
  };

  # 修复默认中文字体显示问题
  fonts.fontDir.enable = true;
  fonts = {
    packages = with pkgs; [
      jetbrains-mono
      fira-code-nerdfont
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      nerd-font-patcher
      noto-fonts-emoji
      noto-fonts-color-emoji
    ];
    fontconfig = {
      antialias = true;
      hinting.enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "FiraCode Nerd Font" ];
        sansSerif = [ "Noto Sans CJK SC" ];
        serif = [ "Noto Serif CJK SC" ];
      };
    };
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 新增配置，强制使用 X11 会话
  services.displayManager.sessionCommands = {
    plasma = "${config.services.xserver.displayManager.sessionPackages.plasma}/bin/startplasma-x11";
  };

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