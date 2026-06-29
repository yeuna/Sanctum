// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// -----------------------------------------------------------------------------
// Sanctum branding preferences.
//
// This file is compiled into the application defaults via the branding
// directory. Upstream Firefox uses it to point first-run / what's-new pages at
// mozilla.org. Sanctum overrides every one of those to a LOCAL value so the
// browser never makes an unsolicited request to any server on first launch,
// after an update, or when opening the start page.
// -----------------------------------------------------------------------------

// First-run and post-update pages: no remote "welcome" or "what's new" fetch.
pref("startup.homepage_override_url", "");
pref("startup.homepage_welcome_url", "");
pref("startup.homepage_welcome_url.additional", "");

// Release notes / support / vendor URLs are shown only on explicit user click;
// keep them local/blank so nothing is contacted implicitly.
pref("app.releaseNotesURL", "about:blank");
pref("app.releaseNotesURL.aboutDialog", "about:blank");
pref("app.releaseNotesURL.prompt", "about:blank");

// "Get help", "Report site issue" and feedback endpoints — blanked.
pref("app.support.baseURL", "about:blank");
pref("app.feedback.baseURL", "about:blank");
pref("app.update.url.details", "about:blank");
pref("app.update.url.manual", "about:blank");

// Vendor URL shown in About — point at the local project page, not a server.
pref("app.vendorURL", "about:blank");
pref("app.privacyURL", "about:blank");

// Profile-down / "your profile cannot be loaded" support link — local.
pref("browser.geolocation.warning.infoURL", "about:blank");
pref("browser.xr.warning.infoURL", "about:blank");
