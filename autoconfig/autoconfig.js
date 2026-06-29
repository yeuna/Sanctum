// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0.
// -----------------------------------------------------------------------------
//  Sanctum autoconfig loader.
//  Installed to:   <install dir>/defaults/pref/autoconfig.js
//  It tells the application to read and apply <install dir>/mozilla.cfg on every
//  startup, BEFORE any profile prefs load — which is what allows mozilla.cfg's
//  lockPref() calls to freeze the privacy switches.
// -----------------------------------------------------------------------------

pref("general.config.filename", "mozilla.cfg");

// 0 = do not byte-shift/obscure the .cfg file (ship it as readable plain text
// so the privacy guarantees are auditable by anyone).
pref("general.config.obscure_value", 0);

// Allow the .cfg to run fully so lockPref() takes effect across all versions.
// Safe here because Sanctum ships the .cfg itself; it is not user-supplied.
pref("general.config.sandbox_enabled", false);
