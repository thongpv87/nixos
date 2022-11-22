{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.jd.graphical.applications;
  isGraphical = let
    cfg = config.jd.graphical;
  in (cfg.xorg.enable == true || cfg.wayland.enable == true);
in {
  options.jd.graphical.applications.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable firefox with config [firefox]";
    };
  };

  config = mkIf cfg.firefox.enable {
    programs.firefox = {
      enable = true;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; let
        firefoxTheme =
          if (config.jd.graphical.theme == "arc-dark")
          then
            (buildFirefoxXpiAddon {
              pname = "arc-dark-theme-firefox";
              addonId = "arc-dark-theme@afnankhan";
              version = "2021.6.2";
              url = "https://addons.mozilla.org/firefox/downloads/file/3786185/arc_dark_theme-2021.6.2-an+fx.xpi";
              sha256 = "TRXQCboplZmxi3/HzU5HYs1xEIO0RRzCClliEu6MEEM=";

              meta = with lib; {
                description = "Arc dark theme";
                license = pkgs.lib.licenses.cc-by-30;
                platforms = pkgs.lib.platforms.all;
              };
            })
          else
            (buildFirefoxXpiAddon {
              pname = "materia-dark-gtk-theme-firefox";
              addonId = "{6aff6b84-e31b-45c3-acfa-ef1b9351607d}";
              version = "1.0";
              url = "https://addons.mozilla.org/firefox/downloads/file/3860526/materia_gtk_dark-1.0.xpi";
              sha256 = "mVcT7ssJmYjIHIgvtAkEahs5u4rsAFigYcPMaPbfhr0=";

              meta = with lib; {
                description = "Materia dark gtk theme";
                license = pkgs.lib.licenses.cc-by-30;
                platforms = pkgs.lib.platforms.all;
              };
            });
      in [
        firefoxTheme
        (buildFirefoxXpiAddon {
          pname = "cookie-quick-manager";
          addonId = "{60f82f00-9ad5-4de5-b31c-b16a47c51558}";
          version = "0.5rc2";
          url = "https://addons.mozilla.org/firefox/downloads/file/3343599/cookie_quick_manager-0.5rc2-an+fx.xpi";
          sha256 = "uCbkQ0OMiAs5mOQuCZ0OGUn/UUiceItQGTuS74BCbG4=";
          meta = with lib; {
            description = "Manage cookies better";
            license = licenses.gpl3;
            platforms = platforms.all;
          };
        })
        (buildFirefoxXpiAddon {
          pname = "kagi-firefox";
          addonId = "search@kagi.com";
          version = "0.2";
          url = "https://addons.mozilla.org/firefox/downloads/file/3942576/kagi_search_for_firefox-0.2.xpi";
          sha256 = "04fk6j7iqsr4vsznn0a52n6630lj3jfhzpxy02y7dyij0fx4dl1z";

          meta = with lib; {
            description = ''
              A simple helper extension for setting Kagi as a default search engine, and automatically logging in to Kagi in private browsing windows.
            '';
            license = licenses.mpl20;
            platforms = platforms.all;
          };
        })
        (buildFirefoxXpiAddon {
          pname = "languagetool-firefox";
          version = "5.8.10";
          addonId = "languagetool-webextension@languagetool.org";
          url = "https://addons.mozilla.org/firefox/downloads/file/4026397/languagetool-5.8.10.xpi";
          sha256 = "sha256-3OPw5oVD5kqX9mnxVOm5pEWSKNiqJVx8whh/bEuremE=";

          meta = with lib; {
            description = ''
              Check your texts for spelling and grammar problems everywhere on the web
            '';
            platforms = platforms.all;
          };
        })

        # Rycee NUR: https://nur.nix-community.org/repos/rycee/
        user-agent-string-switcher
        bypass-paywalls-clean
        redirector
        rust-search-extension
        bitwarden
        ublock-origin
        multi-account-containers
        clearurls
        cookie-autodelete
        firefox-translations

        # Netflix
        netflix-1080p

        # Youtube
        sponsorblock
        return-youtube-dislikes
      ];
      profiles = {
        personal = {
          id = 0;
          settings = let
            newTab = let
              activityStream = "browser.newtabpage.activity-stream";
            in {
              "${activityStream}.feeds.topsites" = true;
              "${activityStream}.feeds.section.highlights" = true;
              "${activityStream}.feeds.section.topstories" = false;
              "${activityStream}.feeds.section.highlights.includePocket" = false;
              "${activityStream}.section.highlights.includePocket" = false;
              "${activityStream}.showSearch" = false;
              "${activityStream}.showSponsoredTopSites" = false;
              "${activityStream}.showSponsored" = false;
            };

            searchBar = {
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
              "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShorcuts" = false;
              "browser.urlbar.showSearchSuggestionsFirst" = false;
            };

            extensions = {
              "extensions.update.autoUpdateDefault" = false;
              "extensions.update.enabled" = false;
            };

            telemetry = {
              "browser.newtabpage.activity-stream.telemetry" = false;
              "browser.newtabpage.activity-stream.feeds.telemetry" = false;
              "browser.ping-centre.telemetry" = false;
              "toolkit.telemetry.reportingpolicy.firstRun" = false;
              "toolkit.telemetry.unified" = false;
              "toolkit.telemetry.archive.enabled" = false;
              "toolkit.telemetry.updatePing.enabled" = false;
              "toolkit.telemetry.shutdownPingSender.enabled" = false;
              "toolkit.telemetry.newProfilePing.enabled" = false;
              "toolkit.telemetry.bhrPing.enabled" = false;
              "toolkit.telemetry.firstShutdownPing.enabled" = false;
              "datareporting.healthreport.uploadEnabled" = false;
              "datareporting.policy.dataSubmissionEnabled" = false;
              "security.protectionspopup.recordEventTelemetry" = false;
              "security.identitypopup.recordEventTelemetry" = false;
              "security.certerrors.recordEventTelemetry" = false;
              "security.app_menu.recordEventTelemetry" = false;
              "toolkit.telemetry.pioneer-new-studies-available" = false;
              "app.shield.optoutstudies.enable" = false;
            };

            domPrivacy = {
              # clipboard events: https://superuser.com/questions/1595994/dont-let-websites-overwrite-clipboard-in-firefox-without-explicitly-giving-perm
              # Breaks copy/paste on websites
              #"dom.event.clipboardevents.enabled" = false;
              "dom.battery.enabled" = false;
            };

            https = {
              "dom.security.https_only_mode" = false;
              "dom.security.https_only_mode_ever_enabled" = false;
            };

            graphics = {
              "media.ffmpeg.vaapi.enabled" = true;
              "media.rdd-ffmpeg.enabled" = true;
              "media.navigator.mediadataencoder_vpx_enabled" = true;
            };

            generalSettings = {
              "widget.use-xdg-desktop-portal.file-picker" = 2;
              "widget.use-xdg-desktop-portal.mime-handler" = 2;
              "browser.aboutConfig.showWarning" = false;
              "browser.shell.checkDefaultBrowser" = false;
              "browser.toolbars.bookmarks.visibility" = "newtab";
              "browser.urlbar.showSearchSuggestionsFirst" = false;
              "extensions.htmlaboutaddons.inline-options.enabled" = false;
              "extensions.htmlaboutaddons.recommendations.enabled" = false;
              "extensions.pocket.enabled" = false;
              "browser.fullscreen.autohide" = false;
              "browser.contentblocking.category" = "standard";
            };

            toolbars = {
              "browser.download.autohideButton" = false;
              "browser.toolbars.bookmarks.visibility" = "newtab";
            };

            passwords = {
              "signon.rememberSignons" = false;
              "signon.autofillForms" = false;
              "signon.generation.enabled" = false;
              "signon.management.page.breach-alerts.enabled" = false;
              "extensions.formautofill.addresses.enabled" = false;
              "extensions.formautofill.creditCards.enabled" = false;
            };

            downloads = {
              "browser.download.useDownloadDir" = false;
            };
          in
            generalSettings
            // https
            // newTab
            // searchBar
            // domPrivacy
            // telemetry
            // graphics
            // downloads
            // toolbars;
        };
      };
    };
  };
}
