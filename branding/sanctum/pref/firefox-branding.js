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

// Release notes / support / vendor URLs are opened only on explicit user
// click, so pointing them at the project's GitHub is consistent with the
// zero-IMPLICIT-contact principle: nothing is fetched until the user asks.
pref("app.releaseNotesURL", "https://github.com/yeuna/Sanctum/releases");
pref("app.releaseNotesURL.aboutDialog", "https://github.com/yeuna/Sanctum/releases");
pref("app.releaseNotesURL.prompt", "https://github.com/yeuna/Sanctum/releases");

// Firefox COMPOSES support links as baseURL + topic slug (e.g. "firefox-help"),
// so a plain page here would break ("about:blank" + slug = invalid URL, which
// made Help -> Sanctum Support error out). End the base with "#" so any
// appended slug becomes a harmless fragment and the user lands on the repo.
pref("app.support.baseURL", "https://github.com/yeuna/Sanctum#");
// Feedback endpoint (menu item is hidden by DisableFeedbackCommands policy).
pref("app.feedback.baseURL", "https://github.com/yeuna/Sanctum/issues#");
pref("app.update.url.details", "https://github.com/yeuna/Sanctum/releases");
pref("app.update.url.manual", "https://github.com/yeuna/Sanctum/releases");

// Vendor / privacy-policy links in the About dialog.
pref("app.vendorURL", "https://github.com/yeuna/Sanctum");
pref("app.privacyURL", "https://github.com/yeuna/Sanctum/blob/main/PRIVACY.md");

// Profile-down / "your profile cannot be loaded" support link — local.
pref("browser.geolocation.warning.infoURL", "about:blank");
pref("browser.xr.warning.infoURL", "about:blank");
