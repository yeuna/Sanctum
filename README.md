<div align="center">
  <img src="assets/sanctum-logo.svg" width="120" alt="Sanctum logo">
  <h1>Sanctum</h1>
  <p><strong>A privacy-hardened fork of Firefox. A sanctuary for your data.</strong></p>
</div>

---

Sanctum is a fork built from Firefox source with one non-negotiable principle:

> **Your usage, your input, your data, and the hardware you run on are holy. They are never logged, never transmitted, never stored, and never used to identify you — by anyone, including us.**

There is no analytics back end. There is no "anonymous" usage ping. There is no
crash uploader, no studies system, no default-browser phone-home agent, and no
fingerprintable hardware surface left exposed by default. The data-collection
machinery is not merely switched off — most of it is **never compiled into the
binary in the first place**, and the few runtime switches that remain are
**locked** so nothing can turn them back on.

## How Sanctum removes data collection — four layers

| # | Layer | File(s) | What it does |
|---|-------|---------|--------------|
| 1 | **Compile-time** | [`mozconfig`](mozconfig) | The crash reporter, the Windows default-browser agent, and the telemetry / data-reporting / health-report / Normandy subsystems are excluded from the build. A binary that doesn't exist can't phone home. |
| 2 | **Compiled-in defaults** | [`prefs/sanctum.js`](prefs/sanctum.js) | ~150 verified preferences set privacy-first defaults: telemetry, captive-portal probes, connectivity checks, prefetch, Safe Browsing, Pocket, search-suggestion keystroke streaming, push, GMP/DRM auto-download — all off. resistFingerprinting + strict Enhanced Tracking Protection — on. |
| 3 | **Locked autoconfig** | [`autoconfig/`](autoconfig/) | `lockPref()` freezes the "holy" switches (anything that could transmit who you are or what hardware you run). They appear greyed-out in `about:config` and **cannot** be re-enabled by an extension, a synced setting, or an accidental edit. |
| 4 | **Enterprise policy** | [`distribution/policies.json`](distribution/policies.json) | A durable, profile-proof enforcement layer that re-asserts every kill switch at each launch. |

Full rationale, the threat model, and the complete itemized list of what was
removed and why are in **[PRIVACY.md](PRIVACY.md)**.

## Quick start (Windows)

Prerequisites: **MozillaBuild**, **Visual Studio 2022** (Desktop development
with C++ + Windows SDK), **Git**, ~40 GB free disk, 8 GB+ RAM. See
**[BUILD.md](BUILD.md)** for the detailed walkthrough.

```powershell
# from the repo root, in PowerShell
powershell -ExecutionPolicy Bypass -File scripts\build-all.ps1 -SourceRef esr140
```

That single command fetches the Firefox ESR source, bootstraps the toolchain,
applies the Sanctum overlay, compiles, and packages a portable build plus a
Windows installer into `dist\`.

Run the individual steps instead if you prefer:

```powershell
scripts\01-fetch-source.ps1     # clone Firefox ESR source
scripts\00-bootstrap.ps1        # pull the build toolchain (mach bootstrap)
scripts\02-apply-overlay.ps1    # branding + prefs + locks + audit
scripts\03-build.ps1            # compile
scripts\04-package.ps1          # portable ZIP + installer (+ sign if cert set)
scripts\05-sign.ps1             # optional: (re)sign artifacts in dist\
```

## Automated builds & signing (CI)

`.github/workflows/build.yml` builds Sanctum on a Windows runner and publishes a
portable ZIP, an installer, and `SHA256SUMS.txt` — triggered manually or by
pushing a `v*` tag (which also creates a GitHub Release). Add the
`SANCTUM_SIGN_PFX_BASE64` + `SANCTUM_SIGN_PFX_PASSWORD` repository secrets and the
installer is Authenticode-signed automatically; without them the build still
succeeds and ships unsigned. Full setup — including a self-hosted-runner note and
an Azure Trusted Signing alternative — is in **[CI.md](CI.md)**.

## Repository layout

```
Firefox Privacy/
├── mozconfig                     # layer 1 — compile-time removals
├── prefs/sanctum.js              # layer 2 — privacy default preferences
├── autoconfig/                   # layer 3 — locked mozilla.cfg + loader
│   ├── mozilla.cfg
│   └── autoconfig.js
├── distribution/policies.json    # layer 4 — enterprise policy enforcement
├── branding/sanctum/             # name, logo, icons, brand strings
│   ├── configure.sh              #   sets the app display name
│   ├── pref/firefox-branding.js  #   local first-run / what's-new URLs
│   ├── content/                  #   logos & vector assets
│   ├── locales/en-US/            #   brand.ftl / .properties / .dtd
│   └── default*.png, *.ico       #   window & taskbar icons
├── patches/                      # optional source-level diffs + audit strategy
├── scripts/                      # Windows build pipeline (PowerShell)
│   ├── 00-bootstrap.ps1 … 05-sign.ps1
│   ├── build-all.ps1
│   ├── ci/mozconfig-ci.append    #   sccache fragment (CI only)
│   └── lib/{common.ps1, harden_sources.py}
├── .github/workflows/build.yml   # CI: build + sign + release
├── BUILD.md                      # build instructions
├── CI.md                         # CI pipeline + code-signing setup
├── PRIVACY.md                    # threat model + full removal inventory
└── VERIFY.md                     # how to prove the claims yourself
```

## Verify it yourself — don't trust, check

Privacy claims are worthless if you can't audit them. **[VERIFY.md](VERIFY.md)**
shows how to confirm, with your own packet capture, that a fresh Sanctum profile
makes **zero** unsolicited network connections at startup, after an update, and
on a blank new tab — and how the build-time audit (`harden_sources.py audit`)
gates the build on there being no live telemetry endpoint.

## License & trademark

Sanctum is built from Firefox source and is distributed under the
**[Mozilla Public License 2.0](https://www.mozilla.org/MPL/2.0/)**, the same
license as the upstream code it derives from.

Firefox is a trademark of the Mozilla Foundation. **Sanctum is an independent
fork and is not produced by, endorsed by, or affiliated with Mozilla.** Per
Mozilla's trademark policy, a modified build must not ship under Firefox
branding — which is exactly why Sanctum carries its own name, logo, and
identity (see `branding/`).
