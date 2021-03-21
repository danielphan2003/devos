{ pkgs, lib, config, ... }:
with lib;
let
  inherit (attrsets) mapAttrsToList;
  inherit (lists) foldr;
  inherit (strings) hasSuffix tolower;

  cfg = config.programs.spicetify;

  pipeConcat = foldr (a: b: a + "|" + b) "";
  lineBreakConcat = foldr (a: b: a + "\n" + b) "";
  boolToString = x: if x then "1" else "0";
  makeLnCommands = type: (mapAttrsToList (name: path: "ln -sf ${path} ./${type}/${name}"));

  # Setup spicetify
  spicetify-wrapper = "SPICETIFY_CONFIG=. ${pkgs.spicetify-cli}/bin/spicetify-cli";

  # Dribbblish is a theme which needs a couple extra settings
  isDribbblish = cfg.theme == "Dribbblish" || cfg.theme == "DribbblishDynamic"; 
  dribbblishScript = if hasSuffix "Dynamic" cfg.theme then "dribbblish-dynamic.js" else "${tolower cfg.theme}.js";
  
  extraCommands = (if isDribbblish then "cp ./Themes/${cfg.theme}/${dribbblishScript} ./Extensions \n" else "")
    + (lineBreakConcat (makeLnCommands "Themes" cfg.thirdPartyThemes))
    + (lineBreakConcat (makeLnCommands "Extensions" cfg.thirdPartyExtensions))
    + (lineBreakConcat (makeLnCommands "CustomApps" cfg.thirdPartyCustomApps));

  customAppsFixupCommands = lineBreakConcat (makeLnCommands "Apps" cfg.thirdPartyCustomApps);
  
  injectCssOrDribbblish = boolToString (isDribbblish || cfg.injectCss);
  replaceColorsOrDribbblish = boolToString (isDribbblish || cfg.replaceColors);
  overwriteAssetsOrDribbblish = boolToString (isDribbblish || cfg.overwriteAssets);

  extensionString = pipeConcat ((if isDribbblish then [ dribbblishScript ] else [ ]) ++ cfg.enabledExtensions);
  customAppsString = pipeConcat cfg.enabledCustomApps;
  spotifyLaunchFlagsString = pipeConcat cfg.spotifyLaunchFlags;
in
{
  options.programs.spicetify = {
    enable = lib.mkEnableOption "A modded Spotify";
    extraConfig = mkOption {
      description = ''
        Extra configuration options to pass to `spicetify-cli`.
        Useful if you are using a newer version of Spicetify and our module has not
        been updated to reflect that change yet.
      '';
      type = jsonFormat.type;
      default = { };
      example = literalExample ''
        {
          "song_page" = 1;
          "fastUser_switching" = 0;
        }
      '';
    };
    spotifyPackage = mkOption {
      description = ''
        Spotify package to use.
        Override this if you want to use a custom spotify derivation to base
        `spicetify-cli` on.
      '';
      type = with types; package;
      default = pkgs.spotify-unwrapped;
      example = literalExample "pkgs.spotifywm";
    };
    extraPackages = mkOption {
      description = ''
        Extra packages to install.
        List addition packages here that improve Spotify functionalities.
      '';
      type = with types; listOf package;
      default = [ ];
      example = literalExample "[ pkgs.spotify-tui ]";
    };
    theme = mkOption {
      description = "Theme for Spotify.";
      type = with types; str;
      default = "SpicetifyDefault";
    };
    colorScheme = mkOption {
      description = ''
        Choose your theme's color scheme. This can be found at 
        https://github.com/morpheusthewhite/spicetify-themes/<your-theme>/README.md
      '';
      type = with types; str;
      default = "";
      example = "dark";
    };
    thirdPartyThemes = mkOption {
      description = ''
        List your own themes here.
      '';
      type = with types; attrs;
      default = { };
    };
    thirdPartyExtensions = mkOption {
      description = ''
        List your own extensions here.
      '';
      type = with types; attrs;
      default = { };
      example = literalExample ''
        let av = pkgs.fetchFromGitHub {
          owner = "amanharwara";
          repo = "spicetify-autoVolume";
        };
        in { "autoVolume.js" = "${av}/autoVolume.js" };
      '';
    };
    thirdPartyCustomApps = mkOption {
      description = ''
      '';
      type = with types; attrs;
      default = { };
    };
    enabledExtensions = mkOption {
      description = ''
        Basically are Javascript files that will be evaluated along with Spotify main javascript.
        Available extensions are: Auto Skip Videos, Bookmark, Christian Spotify, DJ Mode, 
        Full App Display, Keyboard Shortcut, Loopy Loop, New Release, Queue All, Shuffle+, 
        Trash Bin.
      '';
      type = with types; listOf str;
      default = [ ];
      example =  [ "autoVolume.js" "trashbin.js" ];
    };
    enabledCustomApps = mkOption {
      description = ''
        Inject custom apps to Spotify and access them in left sidebar.
        Available custom apps are: Reddit.
      '';
      type = with types; listOf str;
      default = [ ];
      example = [ "reddit" ];
    };
    spotifyLaunchFlags = mkOption {
      description = ''
        Specify commandline flags to launch/restart Spotify. Useful if you are
        using impermanance and Spotify does not login automatically for some reasons.
      '';
      type = with types; listOf str;
      default = [ ];
      example = [ "--transparent-window-controls" "--remote-debugging-port=9222" ];
    };
    injectCss = mkOption {
      type = with types; bool;
      default = false;
    };
    replaceColors = mkOption {
      type = with types; bool;
      default = false;
    };
    overwriteAssets = mkOption {
      type = with types; bool;
      default = false;
    };
    disableSentry = mkOption {
      type = with types; bool;
      default = true;
    };
    disableUiLogging = mkOption {
      type = with types; bool;
      default = true;
    };
    removeRtlRule = mkOption {
      type = with types; bool;
      default = true;
    };
    exposeApis = mkOption {
      type = with types; bool;
      default = true;
    };
    disableUpgradeCheck = mkOption {
      type = with types; bool;
      default = true;
    };
    fastUserSwitching = mkOption {
      type = with types; bool;
      default = false;
    };
    visualizationHighFramerate = mkOption {
      type = with types; bool;
      default = false;
    };
    radio = mkOption {
      type = with types; bool;
      default = false;
    };
    songPage = mkOption {
      type = with types; bool;
      default = false;
    };
    experimentalFeatures = mkOption {
      type = with types; bool;
      default = false;
    };
    home = mkOption {
      type = with types; bool;
      default = false;
    };
    lyricAlwaysShow = mkOption {
      type = with types; bool;
      default = false;
    };
    lyricForceNoSync = mkOption {
      type = with types; bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (cfg.spotifyPackage.overrideAttrs (oldAttrs: rec {
        postInstall = with cfg; ''
          touch $out/prefs
          mkdir Themes
          mkdir Extensions
          mkdir CustomApps
          find ${pkgs.spicetify-themes} -maxdepth 1 -type d -exec ln -s {} Themes \;
          ${extraCommands}
          
          ${spicetify-wrapper} config \
            spotify_path "$out/share/spotify" \
            prefs_path "$out/prefs" \
            current_theme ${theme} \
            ${if 
                colorScheme != ""
              then 
                ''color_scheme "${colorScheme}" \'' 
              else 
                ''\'' }
            ${if 
                extensionString != ""
              then 
                ''extensions "${extensionString}" \'' 
              else 
                ''\'' }
            ${if
                customAppsString != ""
              then 
                ''custom_apps "${customAppsString}" \'' 
              else 
                ''\'' }
            ${if
              spotifyLaunchFlagsString != ""
            then 
              ''spotify_launch_flags "${spotifyLaunchFlagsString}" \'' 
            else 
              ''\'' }
            inject_css ${injectCssOrDribbblish} \
            replace_colors ${replaceColorsOrDribbblish} \
            overwrite_assets ${overwriteAssetsOrDribbblish} \
            disable_sentry ${boolToString disableSentry} \
            disable_ui_logging ${boolToString disableUiLogging} \
            remove_rtl_rule ${boolToString removeRtlRule} \
            expose_apis ${boolToString exposeApis} \
            disable_upgrade_check ${boolToString disableUpgradeCheck} \
            fastUser_switching ${boolToString fastUserSwitching} \
            visualization_high_framerate ${boolToString visualizationHighFramerate} \
            radio ${boolToString radio} \
            song_page ${boolToString songPage} \
            experimental_features ${boolToString experimentalFeatures} \
            home ${boolToString home} \
            lyric_always_show ${boolToString lyricAlwaysShow} \
            lyric_force_no_sync ${boolToString lyricForceNoSync }
          ${spicetify-wrapper} backup apply
          cd $out/share/spotify
          ${customAppsFixupCommands}
        '';
      }))
    ];
  };
}
