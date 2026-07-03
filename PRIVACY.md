# Sanctum — Privacy Design & Threat Model

> **Principle.** End-user application data — what you do, what you type, what you
> visit — and the identity of the hardware you run on are *holy*. Sanctum never
> logs, transmits, or stores them, and exposes no default channel by which any
> third party (including the project) could. Where Firefox collects "anonymous"
> data, Sanctum collects **none**.

This document states the threat model, then inventories **every** data-collection
or phone-home vector and exactly how Sanctum neutralizes each one. Every
preference name was verified against the [arkenfox user.js](https://github.com/arkenfox/user.js),
[LibreWolf settings](https://librewolf.net/docs/settings/), and
[searchfox.org/firefox-main](https://searchfox.org/firefox-main/source/) for the
Firefox 140 ESR era.

---

## 1. Threat model

**What we protect**

1. **Identity of the user.** Nothing that distinguishes *you* from another user leaves the machine: no client IDs, no profile IDs, no usage statistics, no crash dumps, no "interaction" counts.
2. **Content of use.** URLs, search keystrokes, form values, downloads, and visited-page metadata stay on the device.
3. **Identity of the hardware.** CPU core count, GPU model, RAM, screen geometry, timezone, fonts, audio/canvas signatures, battery, sensors, and network interface addresses are not exposed to web content in a distinguishing way.

**Adversaries considered**

- **The vendor (Mozilla / us).** Sanctum assumes the *project itself* must not be trusted with your data. That is why removal is at compile time and the switches are locked — there is no "trust us, it's off" surface.
- **Websites & third-party trackers.** Fingerprinting, cross-site cookies, link auditing, beacons, prefetch, and referer leakage are blocked by default.
- **Network observers (ISP / LAN).** Implicit, unsolicited connections that would reveal you are online or what you run are removed. (Note: Sanctum does not bundle a VPN; on-path observers still see the destinations you deliberately visit.)

**Explicit non-goals.** Sanctum is not anonymity-over-network software like Tor;
it does not route traffic through relays and cannot hide your IP from sites you
choose to visit. It removes *the browser's own* data collection and minimizes
*passive* fingerprintability. Combine with a trustworthy VPN/Tor for network-level
anonymity.

---

## 2. The four removal layers (precedence high → low)

| Layer | Where | Reversible by user? | Purpose |
|---|---|---|---|
| Compile-time defines | `mozconfig` | No (rebuild required) | The collection code isn't in the binary. |
| Locked autoconfig | `autoconfig/mozilla.cfg` | No (locked) | Freezes the master kill switches. |
| Enterprise policy | `distribution/policies.json` | No (admin-level) | Profile-proof enforcement at every launch. |
| Default preferences | `prefs/sanctum.js` | Yes (intentionally) | Privacy-first defaults the user *may* tune. |

The "holy" switches sit in all four layers; tunable conveniences sit only in the
default-preferences layer.

---

## 3. Removal inventory

### 3.1 Telemetry & data reporting — *compiled out + locked*

The unified telemetry pipeline and the Firefox Health Report uploader are
excluded from the build by passing `MOZ_TELEMETRY_REPORTING=`,
`MOZ_SERVICES_HEALTHREPORT=`, and `MOZ_NORMANDY=` as **empty configure
options** (merely unsetting the environment variables is NOT enough — the
browser app implies healthreport/normandy ON, and an absent variable lets the
implied default win; an explicit empty option overrides it).
`MOZ_DATA_REPORTING` has no option of its own and derives from
telemetry|healthreport|crashreporter|normandy, so it goes away with them.
The standalone **pingsender** transmitter binary, which upstream builds and
packages unconditionally, is removed at the source level by
`patches/0001-remove-pingsender.patch`. As defense-in-depth the following are
set and the masters are **locked**:

| Preference | Value | Why |
|---|---|---|
| `datareporting.policy.dataSubmissionEnabled` | `false` 🔒 | Master gate for ALL submission. |
| `datareporting.healthreport.uploadEnabled` | `false` 🔒 | FHR upload (also read by the Windows agent). |
| `toolkit.telemetry.unified` | `false` 🔒 | Unified pipeline master. |
| `toolkit.telemetry.enabled` | `false` 🔒 | Telemetry module. |
| `toolkit.telemetry.server` | `data:,` 🔒 | Upload endpoint neutralized. |
| `toolkit.telemetry.archive.enabled` | `false` 🔒 | No local ping archive. |
| `toolkit.telemetry.{newProfile,shutdownPingSender,updatePing,bhrPing,firstShutdown}Ping.enabled` | `false` | Every individual ping. |
| `toolkit.telemetry.coverage.opt-out` / `toolkit.coverage.opt-out` | `true` 🔒 | Opt out of coverage measurement. |
| `toolkit.coverage.endpoint.base` | `""` 🔒 | Coverage endpoint emptied. |
| `app.shield.optoutstudies.enabled` | `false` 🔒 | No study enrollment. |

### 3.2 Normandy / Shield (remote control) — *compiled out + locked*

`MOZ_NORMANDY` is unset, removing Mozilla's remote system that can push prefs,
studies, and rollouts to your browser. `app.normandy.enabled=false 🔒` and
`app.normandy.api_url=""` 🔒 ensure no recipe server is ever contacted.

### 3.3 Crash reporter — *compiled out*

`--disable-crashreporter` removes the Breakpad minidump uploader binary
entirely; no crash data can be generated or transmitted. `breakpad.reportURL`
and the tab-crash report prefs are blanked as backups.

### 3.4 Experiments / messaging / recommendations

| Preference | Value | Why |
|---|---|---|
| `messaging-system.rsexperimentloader.enabled` | `false` 🔒 | Disables the Nimbus experiment enrollment engine. |
| `browser.ping-centre.telemetry` | `false` 🔒 | Activity-stream telemetry transport. |
| `browser.discovery.enabled` | `false` | Google-Analytics-backed extension recommendations. |
| `extensions.getAddons.cache.enabled` | `false` | Stops the daily installed-add-ons ping to AMO. |
| `extensions.htmlaboutaddons.recommendations.enabled` | `false` | No recommendation tiles. |
| `extensions.webservice.discoverURL` | `""` | AMO discovery endpoint emptied. |

### 3.5 Safe Browsing (Google) — *fully disabled*

Firefox's malware/phishing checks are local hash lookups, but the lists are
downloaded **from Google**, revealing your IP and that you run Sanctum on every
update; the remote *download* check uploads executable metadata. Per the
zero-contact principle Sanctum disables Safe Browsing entirely and empties every
Google provider URL (`...downloads.remote.enabled=false`, `provider.google4.*`
and `provider.google.*` URLs `""`, `malware.enabled`/`phishing.enabled=false`).
**Trade-off:** you lose Google's known-bad blocklist; re-enable the two
`*.enabled` prefs if you want it. The Mozilla *tracking-protection* lists
(`provider.mozilla.*`) are deliberately **kept** — they drive ETP and contain no
per-user data.

### 3.6 Captive-portal & connectivity probes — *disabled*

`network.captive-portal-service.enabled=false`, `captivedetect.canonicalURL=""`,
`network.connectivity-service.enabled=false` (+ IPv4/IPv6 URLs `""`). These stop
automatic background requests to `detectportal.firefox.com` that announce you're
online and leak your IP to Mozilla.

### 3.7 Geolocation & region — *no network backends*

`geo.provider.network.url=""`, OS providers off (`ms-windows-location`,
`use_corelocation`, `use_gpsd`, `use_geoclue` = false), `browser.region.network.url=""`,
`browser.region.update.enabled=false`. The Geolocation API itself stays
permission-gated (`geo.enabled` left at default — toggling it is itself a
fingerprint signal).

### 3.8 Search-suggestion keystroke streaming / Pocket / sponsored content

Search suggestions stream what you type to the search provider before you press
Enter — disabled (`browser.search.suggest.enabled=false`,
`browser.urlbar.suggest.searches=false`). Firefox Suggest, trending, add-on/MDN/
weather urlbar features, Pocket, sponsored top-sites and sponsored stories are
all off. (Policy layer locks `FirefoxSuggest` and `FirefoxHome`.)

### 3.9 Prefetch & speculative connections — *disabled*

`network.prefetch-next=false`, `network.dns.disablePrefetch=true` (+ HTTPS),
`network.http.speculative-parallel-limit=0`, `browser.urlbar.speculativeConnect.enabled=false`,
`browser.places.speculativeConnect.enabled=false`, `network.predictor.enabled=false`.
The browser never contacts a server for a link you didn't click.

### 3.10 Certificate revocation — *local, privacy-preserving*

OCSP would phone the certificate's CA on each HTTPS visit, leaking your browsing
history. Sanctum relies on **CRLite** (`security.remote_settings.crlite_filters.enabled=true`,
`security.pki.crlite_mode=2`), which checks revocation against a locally
downloaded filter — no per-site CA call. OCSP is left at its soft-fail default as
a fallback only.

### 3.11 DNS-over-HTTPS — *off by default, documented*

DoH is **not** enabled by default (`network.trr.mode=0`). While DoH hides DNS
from your ISP, it funnels every lookup to one third-party resolver who then sees
all of it — contrary to Sanctum's "no single server gets your data" stance unless
you run the resolver. `doh-rollout.disable-heuristics=true` prevents Firefox from
silently auto-enabling it. To opt in with a resolver you trust (ideally
self-hosted), set `network.trr.mode=3` and `network.trr.uri`.

### 3.12 Fingerprinting & hardware identity — *resistFingerprinting on*

`privacy.resistFingerprinting=true` is the master switch. It spoofs the user
agent, screen/window size (with letterboxing), timezone (→ `Atlantic/Reykjavik`,
UTC), canvas, WebGL vendor/renderer, audio signature, `navigator.hardwareConcurrency`
(CPU cores → 4/8), device enumeration, and fonts. We also force English display
(`privacy.spoof_english=2`) and cap window dimensions.

**Deliberately NOT set:** the per-feature toggles (`webgl.disabled`,
`dom.webaudio.enabled`, `navigator.hardwareConcurrency`, `dom.battery`,
`device.sensors`, `dom.gamepad`, document-font and timezone prefs). RFP already
normalizes these; overriding them by hand *fights* RFP and would make you **more**
unique. (`dom.battery.enabled=false` is the one exception we set, since the
Battery API has no legitimate need and is removed from web content anyway.)

**WebRTC** is left enabled (disabling it breaks calls) but hardened against
LAN/host-IP leaks: `media.peerconnection.ice.default_address_only=true` and
`...proxy_only_if_behind_proxy=true`.

| Hardware signal | Exposure | How Sanctum handles it |
|---|---|---|
| CPU cores | `navigator.hardwareConcurrency` | RFP spoofs to 4/8 |
| GPU model | WebGL vendor/renderer | RFP spoofs (FF140+) |
| RAM | `navigator.deviceMemory` | Not implemented in Firefox — nothing exposed |
| Screen geometry | `window.screen`, media queries | RFP + letterboxing |
| Timezone / locale | JS `Date`, `Intl` | RFP → UTC; `spoof_english` → en-US |
| MAC / LAN IP | WebRTC ICE candidates | `default_address_only` + proxy-only |
| Battery / sensors / gamepad | DOM APIs | RFP hides; Battery API off |
| Fonts / canvas / audio | enumeration & rendering | RFP randomizes/normalizes |

### 3.13 Tracking protection — *Enhanced Tracking Protection: STRICT*

`browser.contentblocking.category="strict"` plus explicit enables turn on total
cookie protection (`network.cookie.cookieBehavior=5` — network-state
partitioning), cross-site cookie blocking, tracker / fingerprinter / cryptominer
blocking, and tracking-query-parameter stripping.

### 3.14 Implicit outbound, referer, beacons, link auditing

`beacon.enabled=false` (sendBeacon analytics), `browser.send_pings=false`
(`<a ping>` click tracking), and referer trimmed to scheme+host on cross-origin
(`network.http.referer.XOriginPolicy=2`, `XOriginTrimmingPolicy=2`,
`defaultPolicy=2`).

### 3.15 Media GMP / DRM — *no auto-download, no manager ping*

`media.gmp-manager.url=data:text/plain,` and `media.gmp-manager.updateEnabled=false`
stop the periodic Mozilla GMP check. DRM is off by default
(`media.eme.enabled=false`, `media.gmp-widevinecdm.enabled=false`) — Widevine is
a closed Google blob. Re-enable if you need Netflix/Spotify.

### 3.16 Push notifications — *disconnected*

`dom.push.enabled=false`, `dom.push.connection.enabled=false`,
`dom.push.serverURL=""` close the persistent socket to
`push.services.mozilla.com`.

### 3.17 Windows default-browser agent — *compiled out + locked*

This is a Windows-only scheduled task that pings Mozilla every 24h and submits a
default-browser telemetry ping. `--disable-default-browser-agent` removes the
binary so **no scheduled task is ever registered**; `default-browser-agent.enabled=false`
🔒 and the `DisableDefaultBrowserAgent` policy are belt-and-suspenders. The
installer is also built to skip task registration.

### 3.18 Background update agent & first-run/what's-new phone-home

The in-app updater is **kept** (security matters), but the *background* update
agent is disabled (`app.update.background.scheduling.enabled=false`,
`app.update.staging.enabled=false`) so nothing contacts the update server while
Sanctum is closed. First-run, post-update, "what's new", UI-tour, VPN-promo, and
"more from Mozilla" pages are blanked (`branding/sanctum/pref/firefox-branding.js`,
`browser.startup.homepage_override.mstone="ignore"`, `browser.uitour.enabled=false`),
so a fresh or freshly-updated profile makes **no** unsolicited request.

---

## 4. What Sanctum deliberately keeps

- **The in-app updater** — security updates outweigh the minimal version/OS/locale exchange an update check requires. (Build with `--disable-updater` if you want zero update machinery and patch by hand.)
- **Mozilla tracking-protection lists** (`provider.mozilla.*`) — they power ETP and carry no per-user data.
- **WebRTC** — disabling it breaks video calls; instead it's hardened against IP leaks.

Each of these is documented so you can change it; none transmits user-identifying
or hardware-identifying data.

---

## 5. Residual exposure (honest limitations)

- **Network destinations you choose** are still visible to your ISP/VPN and the sites themselves — Sanctum is not an anonymity network.
- **Add-ons you install** can have their own telemetry; Sanctum can't police third-party extension code. Install deliberately.
- **The in-app update check** contacts Mozilla's update server with coarse version/OS/locale data when it runs. Disable the updater for a fully air-gapped build.
- **resistFingerprinting can break sites** (canvas-heavy apps, some video). Use per-site exceptions rather than globally disabling RFP, to avoid standing out.

See [VERIFY.md](VERIFY.md) to confirm these claims with your own packet capture.
