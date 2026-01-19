{
  pkgs,
  lib,
  ...
}: {
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # Workaround for COSMIC autologin (similar to GNOME)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.sessionVariables = {
    # Enable clipboard data control (required for clipboard functionality)
    COSMIC_DATA_CONTROL_ENABLED = "1";
  };

  # XDG portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gtk # For GTK app compatibility
    ];
  };

  # Performance optimization: System76 scheduler
  services.system76-scheduler = {
    enable = true;
    useStockConfig = true;
  };

  # Enable monitord for COSMIC Observatory (system monitoring app)
  systemd.services.monitord.wantedBy = lib.mkDefault ["multi-user.target"];

  # Environment packages for COSMIC
  environment.systemPackages = with pkgs; [
    wl-clipboard # Wayland clipboard utilities
  ];

  # ============================================
  # Notes for COSMIC configuration
  # ============================================
  #
  # The DE selector automatically handles basic setup.
  # Additional configuration needed:
  #
  # 1. In stylix.nix, disable GNOME targets:
  #    stylix.targets.gnome.enable = false;
  #    stylix.targets.gnome-text-editor.enable = false;
  #
  # 2. For Firefox theming, add to firefox.nix settings:
  #    "widget.gtk.libadwaita-colors.enabled" = false;
  #
  # 3. Nvidia users with phantom display issues:
  #    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # ============================================
  # For development/latest: Use nixos-cosmic flake
  # ============================================
}
