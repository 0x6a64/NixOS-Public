{
  pkgs,
  lib,
  # Stylix palette; repoints the "gnome-apps" color source (optional so it evaluates standalone)
  colors ? null,
}: let
  version = "1.3.1";
  uuid = "superbar@Furkan-rgb.github.io";

  rgb = base: "[${colors."${base}-rgb-r"}, ${colors."${base}-rgb-g"}, ${colors."${base}-rgb-b"}]";

  nl = lib.concatStringsSep "\n";

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

  # base01 is the darker surface in Kanagawa; both variants collapse to one base16 palette
  newPalette = nl [
    "  return {"
    "    background: ${rgb "base01"},"
    "    foreground: ${rgb "base05"},"
    "    accent: ${rgb "base0D"},"
    "    accentForeground: ${rgb "base0D"},"
    "  };"
  ];

  # Without disable_unredirect() mutter direct-scans-out full-monitor windows and the bar never shows
  # (superbar #16); tied to visibility, released on disable
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

    # "gnome-apps" is the only source setting foreground and accent too; de/dconf.nix selects it, meaning "stylix" after this patch
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
