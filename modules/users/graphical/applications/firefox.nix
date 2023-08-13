{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.thongpv87.graphical.applications;
  isGraphical = let cfg = config.thongpv87.graphical;
  in (cfg.xorg.enable == true || cfg.wayland.enable == true);
in {
  options.thongpv87.graphical.applications.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable firefox with config [firefox]";
    };
  };

  config = mkIf cfg.firefox.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraNativeMessagingHosts = with pkgs.nur.repos.wolfangaukang;
          [ vdhcoapp ];
      };
      profiles = {
        personal = {
          id = 0;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            (buildFirefoxXpiAddon {
              pname = "cookie-quick-manager";
              addonId = "{60f82f00-9ad5-4de5-b31c-b16a47c51558}";
              version = "0.5rc2";
              url =
                "https://addons.mozilla.org/firefox/downloads/file/3343599/cookie_quick_manager-0.5rc2-an+fx.xpi";
              sha256 = "uCbkQ0OMiAs5mOQuCZ0OGUn/UUiceItQGTuS74BCbG4=";
              meta = with lib; {
                description = "Manage cookies better";
                license = licenses.gpl3;
                platforms = platforms.all;
              };
            })
            # Rycee NUR: https://nur.nix-community.org/repos/rycee/
            # bypass-paywalls-clean
            redirector
            bitwarden
            ublock-origin
            multi-account-containers
            clearurls
            cookie-autodelete
            firefox-translations

            # Netflix
            # netflix-1080p

            # Youtube
            sponsorblock
            return-youtube-dislikes
          ];
          settings = let
            newTab = let activityStream = "browser.newtabpage.activity-stream";
            in {
              "${activityStream}.feeds.topsites" = true;
              "${activityStream}.feeds.section.highlights" = true;
              "${activityStream}.feeds.section.topstories" = false;
              "${activityStream}.feeds.section.highlights.includePocket" =
                false;
              "${activityStream}.section.highlights.includePocket" = false;
              "${activityStream}.showSearch" = false;
              "${activityStream}.showSponsoredTopSites" = false;
              "${activityStream}.showSponsored" = false;
            };

            searchBar = {
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
              "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShorcuts" =
                false;
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

            privacy = {
              # clipboard events: https://superuser.com/questions/1595994/dont-let-websites-overwrite-clipboard-in-firefox-without-explicitly-giving-perm
              # Breaks copy/paste on websites
              #"dom.event.clipboardevents.enabled" = false;
              "dom.battery.enabled" = false;
              # "privacy.resistFingerprinting" = true;
            };

            https = {
              "dom.security.https_only_mode" = false;
              "dom.security.https_only_mode_ever_enabled" = false;
            };

            graphics = {
              "media.ffmpeg.vaapi.enabled" = true;
              "media.gpu-process-decoder" = true;
              "dom.webgpu.enabled" = true;
              "gfx.webrender.all" = true;
              "layers.mlgpu.enabled" = true;
              "layers.gpu-process.enabled" = true;
            };

            generalSettings = {
              "widget.use-xdg-desktop-portal.file-picker" = 2;
              "widget.use-xdg-desktop-portal.mime-handler" = 2;
              "browser.aboutConfig.showWarning" = false;
              "browser.tabs.warnOnClose" = true;
              "browser.tabs.warnOnCloseOtherTabs" = true;
              "browser.warnOnQuit" = true;
              "browser.shell.checkDefaultBrowser" = false;
              "browser.urlbar.showSearchSuggestionsFirst" = false;
              "extensions.htmlaboutaddons.inline-options.enabled" = false;
              "extensions.htmlaboutaddons.recommendations.enabled" = false;
              "extensions.pocket.enabled" = false;
              "browser.fullscreen.autohide" = false;
              "browser.contentblocking.category" = "standard";
              # "browser.display.use_document_fonts" = 0; Using enable-browser-fonts extension instead
            };

            toolbars = {
              "browser.tabs.firefox-view" = false;
              "browser.toolbars.bookmarks.visibility" = "newtab";
            };

            passwords = {
              "signon.rememberSignons" = false;
              "signon.autofillForms" = false;
              "signon.generation.enabled" = false;
              "signon.management.page.breach-alerts.enabled" = false;
            };

            downloads = {
              "browser.download.useDownloadDir" = false;
              "browser.download.autohideButton" = false;
              "browser.download.always_ask_before_handling_new_types" = true;
            };
          in generalSettings // passwords // extensions // https // newTab
          // searchBar // privacy // telemetry // graphics // downloads
          // toolbars;
        };
      };
    };
  };
}
