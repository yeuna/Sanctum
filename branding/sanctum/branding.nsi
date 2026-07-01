# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# NSIS branding defines for Sanctum.
# Required at BUILD time (not only for the optional installer repackage):
# browser/installer/windows/Makefile.in lists branding.nsi in BRANDING_FILES,
# and instgen/helper.exe (the maintenance/uninstall helper packaged inside the
# app) depends on it. Modeled on browser/branding/nightly/branding.nsi.

# BrandFullNameInternal is used for some registry and file system values
# instead of BrandFullName and typically should not be modified.
!define BrandFullNameInternal "Sanctum"
!define BrandFullName         "Sanctum"
!define CompanyName           "sanctumbrowser.org"
!define URLInfoAbout          "https://github.com/yeuna/Sanctum"
!define HelpLink              "https://github.com/yeuna/Sanctum/issues"

# Only consumed by the network stub installer, which Sanctum never builds
# (and would violate the zero-contact principle anyway). Defined to keep the
# NSIS preprocessing identical to upstream; they point at the project releases.
!define URLStubDownloadX86 "https://github.com/yeuna/Sanctum/releases"
!define URLStubDownloadAMD64 "https://github.com/yeuna/Sanctum/releases"
!define URLStubDownloadAArch64 "https://github.com/yeuna/Sanctum/releases"
!define URLManualDownload "https://github.com/yeuna/Sanctum/releases"
!define URLSystemRequirements "https://www.mozilla.org/firefox/system-requirements/"
!define Channel "release"

# The installer's certificate name and issuer expected by the stub installer
# (unused: no stub installer, and Sanctum signing is optional/local).
!define CertNameDownload   "Sanctum"
!define CertIssuerDownload "Sanctum"

# Dialog units are used so the UI displays correctly with the system's DPI
# settings.
!define PROFILE_CLEANUP_LABEL_TOP "35u"
!define PROFILE_CLEANUP_LABEL_LEFT "0"
!define PROFILE_CLEANUP_LABEL_WIDTH "100%"
!define PROFILE_CLEANUP_LABEL_HEIGHT "80u"
!define PROFILE_CLEANUP_LABEL_ALIGN "center"
!define PROFILE_CLEANUP_CHECKBOX_LEFT "center"
!define PROFILE_CLEANUP_CHECKBOX_WIDTH "100%"
!define PROFILE_CLEANUP_BUTTON_LEFT "center"
!define INSTALL_BLURB_TOP "137u"
!define INSTALL_BLURB_WIDTH "60u"
!define INSTALL_FOOTER_TOP "-48u"
!define INSTALL_FOOTER_WIDTH "250u"
!define INSTALL_INSTALLING_TOP "70u"
!define INSTALL_INSTALLING_LEFT "0"
!define INSTALL_INSTALLING_WIDTH "100%"
!define INSTALL_PROGRESS_BAR_TOP "112u"
!define INSTALL_PROGRESS_BAR_LEFT "20%"
!define INSTALL_PROGRESS_BAR_WIDTH "60%"
!define INSTALL_PROGRESS_BAR_HEIGHT "12u"

!define PROFILE_CLEANUP_CHECKBOX_TOP_MARGIN "20u"
!define PROFILE_CLEANUP_BUTTON_TOP_MARGIN "20u"
!define PROFILE_CLEANUP_BUTTON_X_PADDING "40u"
!define PROFILE_CLEANUP_BUTTON_Y_PADDING "4u"

# Font settings that can be customized for each channel
!define INSTALL_HEADER_FONT_SIZE 28
!define INSTALL_HEADER_FONT_WEIGHT 400
!define INSTALL_INSTALLING_FONT_SIZE 28
!define INSTALL_INSTALLING_FONT_WEIGHT 400

# UI Colors that can be customized for each channel
!define COMMON_TEXT_COLOR 0xFFFFFF
!define COMMON_BACKGROUND_COLOR 0x000000
!define INSTALL_INSTALLING_TEXT_COLOR 0xFFFFFF
