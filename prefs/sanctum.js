// =============================================================================
//  Sanctum — privacy-hardened Firefox fork
//  prefs/sanctum.js : compiled-in default preferences
// -----------------------------------------------------------------------------
//  The build overlay appends this file to browser/app/profile/firefox.js so
//  every value below becomes a DEFAULT of the shipped browser. Users may still
//  change anything here, EXCEPT the master data-submission switches, which are
//  additionally LOCKED in autoconfig/mozilla.cfg so they can never be re-armed.
//
//  Every pref name was verified against the arkenfox user.js, LibreWolf
//  settings, and searchfox.org/firefox-main (Firefox 140 ESR era). Where a
//  preference is intentionally NOT set, a comment explains why (usually because
//  resistFingerprinting already covers it and setting it manually would make
//  the user MORE identifiable).
// =============================================================================

/* ###########################################################################
 * 0. MASTER KILL-SWITCH  — gates ALL outbound data submission
 * ######################################################################### */
pref("datareporting.policy.dataSubmissionEnabled", false);   // master gate
pref("datareporting.healthreport.uploadEnabled", false);     // FHR upload off
pref("datareporting.policy.dataSubmissionPolicyAcceptedVersion", 2);
pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);

/* ###########################################################################
 * 1. TELEMETRY  (pipeline is also compiled out via mozconfig)
 * ######################################################################### */
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.server", "data:,");
pref("toolkit.telemetry.server_owner", "");
pref("toolkit.telemetry.archive.enabled", false);
pref("toolkit.telemetry.newProfilePing.enabled", false);
pref("toolkit.telemetry.shutdownPingSender.enabled", false);
pref("toolkit.telemetry.shutdownPingSender.enabledFirstSession", false);
pref("toolkit.telemetry.updatePing.enabled", false);
pref("toolkit.telemetry.bhrPing.enabled", false);
pref("toolkit.telemetry.firstShutdownPing.enabled", false);
pref("toolkit.telemetry.coverage.opt-out", true);
pref("toolkit.coverage.opt-out", true);
pref("toolkit.coverage.endpoint.base", "");
pref("toolkit.telemetry.ecosystemtelemetry.enabled", false);
pref("toolkit.telemetry.pioneer-new-studies-available", false);
pref("app.shield.optoutstudies.enabled", false);

/* ###########################################################################
 * 2. NORMANDY / SHIELD  (remote pref/study injection — compiled out too)
 * ######################################################################### */
pref("app.normandy.enabled", false);
pref("app.normandy.api_url", "");
pref("app.normandy.first_run", false);

/* ###########################################################################
 * 3. CRASH REPORTER  (binary compiled out; these are belt-and-suspenders)
 * ######################################################################### */
pref("breakpad.reportURL", "");
pref("browser.tabs.crashReporting.sendReport", false);
pref("browser.crashReports.unsubmittedCheck.enabled", false);
pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

/* ###########################################################################
 * 4. EXPERIMENTS / MESSAGING / PING-CENTRE / AMO RECOMMENDATIONS
 * ######################################################################### */
pref("browser.ping-centre.telemetry", false);
pref("browser.discovery.enabled", false);
pref("messaging-system.rsexperimentloader.enabled", false);
pref("messaging-system.askForFeedback", false);
pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
pref("browser.newtabpage.activity-stream.telemetry", false);
pref("extensions.getAddons.cache.enabled", false);
pref("extensions.htmlaboutaddons.recommendations.enabled", false);
pref("extensions.webservice.discoverURL", "");
pref("extensions.getAddons.discovery.api_url", "");
// Hide the about:addons "Recommendations" pane entirely — its backend URLs
// are blanked above, so leaving the pane visible shows a broken/empty page
// (and it advertises what "Firefox recommends").
pref("extensions.getAddons.showPane", false);

/* ###########################################################################
 * 5. SAFE BROWSING  (Google)
 * -----------------------------------------------------------------------------
 *  Sanctum disables Safe Browsing entirely. The local malware/phishing lists
 *  themselves are downloaded FROM Google servers, so even "local" checking
 *  reveals your IP + that you run Sanctum to Google on every list update. Per
 *  the project's zero-contact principle we cut it off completely.
 *  TRADE-OFF: you lose Google's known-malware/phishing blocklist. Re-enable by
 *  flipping the two *.enabled prefs back to true if you want that protection.
 * ######################################################################### */
pref("browser.safebrowsing.malware.enabled", false);
pref("browser.safebrowsing.phishing.enabled", false);
pref("browser.safebrowsing.downloads.enabled", false);
pref("browser.safebrowsing.downloads.remote.enabled", false);
pref("browser.safebrowsing.downloads.remote.url", "");
pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
pref("browser.safebrowsing.blockedURIs.enabled", false);
pref("browser.safebrowsing.provider.google4.gethashURL", "");
pref("browser.safebrowsing.provider.google4.updateURL", "");
pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
pref("browser.safebrowsing.provider.google.gethashURL", "");
pref("browser.safebrowsing.provider.google.updateURL", "");
pref("browser.safebrowsing.allowOverride", false);
// NOTE: provider.mozilla.* URLs are deliberately LEFT ALONE — they drive
// Enhanced Tracking Protection lists, not Google Safe Browsing.

/* ###########################################################################
 * 6. CAPTIVE PORTAL & CONNECTIVITY CHECKS  (phone home to detectportal.firefox.com)
 * ######################################################################### */
pref("network.captive-portal-service.enabled", false);
pref("captivedetect.canonicalURL", "");
pref("network.connectivity-service.enabled", false);
pref("network.connectivity-service.IPv4.url", "");
pref("network.connectivity-service.IPv6.url", "");

/* ###########################################################################
 * 7. GEOLOCATION & REGION
 * ######################################################################### */
pref("geo.provider.network.url", "");
pref("geo.provider.ms-windows-location", false);   // Windows OS location service
pref("geo.provider.use_corelocation", false);      // macOS
pref("geo.provider.use_gpsd", false);              // Linux
pref("geo.provider.use_geoclue", false);           // Linux
pref("browser.region.network.url", "");
pref("browser.region.update.enabled", false);
// geo.enabled left at default (true): it is permission-gated, and toggling it
// is itself a fingerprintable signal.

/* ###########################################################################
 * 8. SEARCH SUGGESTIONS / FIREFOX SUGGEST / POCKET / NEW TAB
 *    (search suggestions stream your keystrokes to the search provider)
 * ######################################################################### */
pref("browser.search.suggest.enabled", false);
pref("browser.search.suggest.enabled.private", false);
pref("browser.urlbar.suggest.searches", false);
pref("browser.urlbar.quicksuggest.enabled", false);
pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
pref("browser.urlbar.trending.featureGate", false);
pref("browser.urlbar.addons.featureGate", false);
pref("browser.urlbar.mdn.featureGate", false);
pref("browser.urlbar.weather.featureGate", false);
pref("extensions.pocket.enabled", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
pref("browser.newtabpage.activity-stream.showSponsored", false);
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);
pref("browser.newtabpage.activity-stream.default.sites", "");

/* ###########################################################################
 * 9. PREFETCH / SPECULATIVE CONNECTIONS
 *    (contact servers for links you never clicked)
 * ######################################################################### */
pref("network.prefetch-next", false);
pref("network.dns.disablePrefetch", true);
pref("network.dns.disablePrefetchFromHTTPS", true);
pref("network.http.speculative-parallel-limit", 0);
pref("browser.urlbar.speculativeConnect.enabled", false);
pref("browser.places.speculativeConnect.enabled", false);
pref("network.predictor.enabled", false);
pref("network.predictor.enable-prefetch", false);

/* ###########################################################################
 * 10. CERTIFICATE REVOCATION  (privacy-preserving, local)
 * -----------------------------------------------------------------------------
 *  CRLite checks revocation against a locally-downloaded filter — no per-site
 *  call to the CA, so your browsing history never leaks to certificate
 *  authorities. We leave OCSP at its soft-fail default as a fallback.
 * ######################################################################### */
pref("security.remote_settings.crlite_filters.enabled", true);
pref("security.pki.crlite_mode", 2);

/* ###########################################################################
 * 11. DNS-over-HTTPS / TRR
 * -----------------------------------------------------------------------------
 *  Left OFF by default (mode 0). DoH would encrypt DNS from your ISP, but it
 *  also funnels ALL of your DNS to a single third-party resolver who then sees
 *  everything — which conflicts with Sanctum's "no server gets your data"
 *  principle unless YOU run the resolver. To enable with a resolver you trust
 *  (ideally self-hosted), set network.trr.mode = 3 and network.trr.uri.
 * ######################################################################### */
pref("network.trr.mode", 0);
pref("doh-rollout.disable-heuristics", true);   // never auto-enable behind your back
pref("network.trr.confirmationNS", "skip");

/* ###########################################################################
 * 12. FINGERPRINTING & HARDWARE RESISTANCE
 * -----------------------------------------------------------------------------
 *  resistFingerprinting (RFP) is the master switch. It spoofs the user agent,
 *  screen size, timezone (Atlantic/Reykjavik = UTC), canvas, WebGL vendor,
 *  audio, hardwareConcurrency (CPU cores), device enumeration, fonts and more.
 *  CRITICAL: we do NOT set the per-feature prefs (webgl.disabled,
 *  dom.webaudio.enabled, navigator.hardwareConcurrency, battery, sensors,
 *  gamepad, document fonts, timezone, screen) — RFP already handles them and
 *  overriding them manually fights RFP and makes you MORE unique.
 * ######################################################################### */
pref("privacy.resistFingerprinting", true);
pref("privacy.resistFingerprinting.pbmode", true);
pref("privacy.resistFingerprinting.letterboxing", true);
pref("privacy.resistFingerprinting.block_mozAddonManager", true);
pref("privacy.window.maxInnerWidth", 1600);
pref("privacy.window.maxInnerHeight", 900);
pref("privacy.spoof_english", 2);                 // force en-US display + locale

// WebRTC: do NOT disable it (breaks calls). Instead stop it leaking your real
// LAN/host IP addresses behind a VPN/proxy.
pref("media.peerconnection.ice.default_address_only", true);
pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

/* ###########################################################################
 * 13. TRACKING PROTECTION  (Enhanced Tracking Protection — STRICT)
 *     Strict mode enables total cookie protection (network-state partitioning),
 *     cross-site cookie blocking, tracker + fingerprinter + cryptominer
 *     blocking, and query-string stripping.
 * ######################################################################### */
pref("browser.contentblocking.category", "strict");
pref("privacy.trackingprotection.enabled", true);
pref("privacy.trackingprotection.socialtracking.enabled", true);
pref("privacy.trackingprotection.cryptomining.enabled", true);
pref("privacy.trackingprotection.fingerprinting.enabled", true);
pref("privacy.query_stripping.enabled", true);
pref("privacy.query_stripping.enabled.pbmode", true);
pref("network.cookie.cookieBehavior", 5);          // dFPI / total cookie protection
pref("privacy.partition.serviceWorkers", true);
pref("privacy.partition.always_partition_third_party_non_cookie_storage", true);

/* ###########################################################################
 * 14. IMPLICIT OUTBOUND / REFERER / BEACONS / LINK AUDITING
 * ######################################################################### */
pref("beacon.enabled", false);                     // navigator.sendBeacon()
pref("browser.send_pings", false);                 // <a ping> click tracking
pref("network.http.referer.XOriginPolicy", 2);     // referer only on full-host match
pref("network.http.referer.XOriginTrimmingPolicy", 2);
pref("network.http.referer.defaultPolicy", 2);
pref("network.http.referer.defaultPolicy.pbmode", 2);

/* ###########################################################################
 * 15. MEDIA / DRM / GMP  (binaries downloaded from Mozilla/Google)
 * -----------------------------------------------------------------------------
 *  The GMP "manager" periodically pings Mozilla; we point it at a data: URI so
 *  it never reaches out. DRM (Widevine) is off by default — it is a closed
 *  Google blob. Re-enable media.eme.enabled + media.gmp-widevinecdm.enabled if
 *  you need Netflix/Spotify/etc.
 * ######################################################################### */
pref("media.gmp-manager.url", "data:text/plain,");
pref("media.gmp-manager.updateEnabled", false);
pref("media.gmp-manager.cert.checkAttributes", false);
pref("media.eme.enabled", false);
pref("media.gmp-widevinecdm.visible", false);
pref("media.gmp-widevinecdm.enabled", false);

/* ###########################################################################
 * 16. PUSH NOTIFICATIONS  (persistent socket to push.services.mozilla.com)
 * ######################################################################### */
pref("dom.push.enabled", false);
pref("dom.push.connection.enabled", false);
pref("dom.push.serverURL", "");

/* ###########################################################################
 * 17. BACKGROUND UPDATE AGENT + DEFAULT-BROWSER AGENT (Windows)
 * -----------------------------------------------------------------------------
 *  The default-browser agent binary is compiled out (mozconfig). These prefs
 *  are defense-in-depth and also disable the background UPDATE scheduled task,
 *  which would otherwise contact the update server while Sanctum is closed.
 * ######################################################################### */
pref("default-browser-agent.enabled", false);      // NOTE: bare name, no prefix
pref("app.update.background.scheduling.enabled", false);
pref("app.update.staging.enabled", false);
pref("app.update.url.details", "about:blank");
pref("app.update.url.manual", "about:blank");

/* ###########################################################################
 * 18. MISC HARDENING & NUISANCE PHONE-HOME REMOVAL
 * ######################################################################### */
pref("browser.aboutConfig.showWarning", false);
pref("browser.tabs.firefox-view", false);
pref("browser.uitour.enabled", false);             // remote-driven UI tours
pref("browser.uitour.url", "");
pref("browser.startup.homepage_override.mstone", "ignore"); // no "what's new" page
pref("browser.messaging-system.whatsNewPanel.enabled", false);
pref("browser.preferences.moreFromMozilla", false);
pref("browser.vpn_promo.enabled", false);
pref("browser.promo.focus.enabled", false);
pref("identity.fxaccounts.toolbar.enabled", false);
pref("browser.contentblocking.report.lockwise.enabled", false);
pref("browser.contentblocking.report.monitor.enabled", false);
pref("nimbus.telemetry.enabled", false);
pref("dom.security.unexpected_system_load_telemetry_enabled", false);
pref("network.trr.send_user-agent-headers", false);
// Trim the user-agent / build id leakage that RFP doesn't normalise:
pref("dom.battery.enabled", false);                // Battery Status API off entirely

