{
  pkgs,
  lib,
  # Stylix palette; when supplied, the "gnome-apps" color source is repointed at
  # it (see postPatch). Optional so the package still evaluates standalone.
  colors ? null,
}: let
  version = "1.3.1";
  uuid = "superbar@Furkan-rgb.github.io";

  # Superbar stores colors as [r, g, b] literals with decimal components.
  rgb = base: "[${colors."${base}-rgb-r"}, ${colors."${base}-rgb-g"}, ${colors."${base}-rgb-b"}]";

  nl = lib.concatStringsSep "\n";

  # Upstream builds the palette from Libadwaita's surface table plus the live
  # GNOME accent preference, neither of which knows about stylix.
  oldPalette = nl [
    "  const resolvedVariant = variant === \"dark\" ? \"dark\" : \"light\";"
    "  const surface = GNOME_APP_SURFACE_COLORS[resolvedVariant];"
    "  const accent = GNOME_ACCENT_COLORS[accentName] ?? GNOME_ACCENT_COLORS.blue;"
    ""
    "  return {"
    "    background: surface.background,"
    "    foreground: surface.foreground,"
    "    accent: accent.background,"
    "    accentForeground:"
    "      resolvedVariant === \"dark\""
    "        ? accent.darkForeground"
    "        : accent.lightForeground,"
    "  };"
  ];

  # base01 surface — in Kanagawa that is #16161d, darker than base00; base05 text,
  # base0D accent. Both theme variants collapse to the same values because a base16
  # scheme has only one palette; stylix.polarity already drives GNOME's color-scheme,
  # so the resolved variant matches it anyway.
  newPalette = nl [
    "  return {"
    "    background: ${rgb "base01"},"
    "    foreground: ${rgb "base05"},"
    "    accent: ${rgb "base0D"},"
    "    accentForeground: ${rgb "base0D"},"
    "  };"
  ];

  # Mutter scans a window that covers the whole monitor straight to the display,
  # skipping the stage, so chrome drawn over it never shows. Shell UI calls
  # disable_unredirect() while visible; upstream superbar doesn't, so the bar
  # vanished behind maximized Firefox. Tie the inhibit to the container's
  # visibility, and release it on disable (destroy doesn't notify::visible).
  addChromeOld = "    Main.layoutManager.addChrome(this._container);";
  addChromeNew = nl [
    addChromeOld
    "    this._container.connect(\"notify::visible\", () =>"
    "      this._setUnredirectInhibited(this._container.visible),"
    "    );"
  ];
  removeChromeOld = "      Main.layoutManager.removeChrome(this._container);";
  removeChromeNew = nl [
    "      this._setUnredirectInhibited(false);"
    removeChromeOld
  ];
  abandonOld = "  _abandonOpenSearch() {";
  abandonNew = nl [
    "  _setUnredirectInhibited(inhibit) {"
    "    if (!!this._unredirectInhibited === inhibit) return;"
    "    this._unredirectInhibited = inhibit;"
    "    if (inhibit) global.compositor.disable_unredirect();"
    "    else global.compositor.enable_unredirect();"
    "  }"
    ""
    abandonOld
  ];
in
  pkgs.stdenv.mkDerivation {
    pname = "gnome-shell-extension-superbar";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://github.com/Furkan-rgb/superbar/releases/download/v${version}/superbar%40Furkan-rgb.github.io.shell-extension.zip";
      hash = "sha256-7bKCG/esbqVbeWAOC6mtjSPL4YXqEMxoY9MF6qeUYtU=";
      stripRoot = false;
    };

    nativeBuildInputs = [pkgs.glib];

    dontBuild = true;
    dontConfigure = true;

    # Only the "gnome-apps" color source sets foreground and accent as well as the
    # background, so that is the one repointed at stylix — de/dconf.nix therefore
    # sets color-source = "gnome-apps", which after this patch means "stylix".
    postPatch =
      ''
        substituteInPlace extension.js \
          --replace-fail ${lib.escapeShellArg addChromeOld} ${lib.escapeShellArg addChromeNew} \
          --replace-fail ${lib.escapeShellArg removeChromeOld} ${lib.escapeShellArg removeChromeNew} \
          --replace-fail ${lib.escapeShellArg abandonOld} ${lib.escapeShellArg abandonNew}
      ''
      + lib.optionalString (colors != null) ''
        substituteInPlace appearance.js \
          --replace-fail ${lib.escapeShellArg oldPalette} ${lib.escapeShellArg newPalette}
      '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/gnome-shell/extensions/${uuid}
      cp -r * $out/share/gnome-shell/extensions/${uuid}/

      if [ -d "$out/share/gnome-shell/extensions/${uuid}/schemas" ]; then
        glib-compile-schemas $out/share/gnome-shell/extensions/${uuid}/schemas
      fi
      runHook postInstall
    '';

    passthru = {
      extensionUuid = uuid;
      extensionPortalSlug = "superbar";
    };

    meta = with lib; {
      description = "Keyboard-first Spotlight-style launcher for GNOME Shell";
      homepage = "https://github.com/Furkan-rgb/superbar";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
      maintainers = [];
    };
  }
