#! /bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# -----------------------------------------------------------------------------
# Sanctum branding — privacy-hardened Firefox fork
# This file is sourced by the build system when configured with:
#   ac_add_options --with-branding=browser/branding/sanctum
# It defines every user-visible identity string for the application.
# -----------------------------------------------------------------------------

MOZ_APP_DISPLAYNAME=Sanctum

# The internal "remoting" name controls the profile directory, the remote
# control name and the WM_CLASS. Keeping it distinct from "firefox" guarantees
# Sanctum never shares a profile or a single-instance lock with stock Firefox.
MOZ_APP_REMOTINGNAME=sanctum

# Reverse-DNS bundle identifier (used on macOS; harmless on Windows/Linux).
MOZ_MACBUNDLE_ID=org.sanctumbrowser.sanctum

# Crash reporter is compiled OUT (see mozconfig: --disable-crashreporter), so
# no Socorro app name is required. Left blank intentionally.
MOZ_CRASHREPORTER_APPID=
