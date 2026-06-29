# Verifying Sanctum — don't trust, check

Privacy claims mean nothing if you can't audit them. Here is how to prove, for
yourself, that Sanctum collects and transmits nothing.

## A. Build-time audit (no network needed)

The overlay step runs an auditor that fails the build if any live telemetry /
phone-home endpoint survives as a compiled default:

```powershell
python scripts\lib\harden_sources.py audit --src firefox-src
```

`PASS` ⇒ no enabled data-collection default remains. CI gates on the exit code,
so a build that would phone home cannot be produced.

## B. Confirm the locked switches in the running browser

1. Open `about:config`. Search `datareporting.policy.dataSubmissionEnabled` — it
   shows a **lock** icon, value `false`, and cannot be edited.
2. Open `about:policies` — the Sanctum policy set (DisableTelemetry,
   DisableDefaultBrowserAgent, EnableTrackingProtection…) is listed as **active**.
3. Open `about:telemetry` — it reports telemetry is disabled and there are no
   pings to send.
4. Open `about:studies` — no studies, enrollment disabled.

## C. Packet-capture proof (the real test)

Watch the wire on a **fresh profile** and confirm zero unsolicited traffic.

1. Start a capture filtered to Sanctum's traffic. Easiest cross-checks:
   - **Wireshark** on your interface, or
   - **mitmproxy** / **Fiddler** as an HTTP(S) proxy, or
   - on Windows, `Resource Monitor → Network` filtered to `sanctum.exe`.
2. Launch Sanctum with a brand-new profile and **do nothing**:

   ```bash
   ./mach run --temp-profile        # from the source tree
   # or, for a packaged build:
   sanctum.exe -P --no-remote       # create a throwaway profile
   ```
3. Expected result: **no connections** to `telemetry.mozilla.org`,
   `incoming.telemetry.mozilla.org`, `detectportal.firefox.com`,
   `location.services.mozilla.com`, `push.services.mozilla.com`,
   `normandy.cdn.mozilla.net`, `firefox.settings.services.mozilla.com`
   (Safe Browsing / Remote Settings), or `*.googleapis.com`.
4. Open a **new tab** and the **about** dialog — still nothing outbound.
5. Compare against stock Firefox doing the same thing to see the difference.

> Note: if you opt back into the in-app updater check, you will see a single
> connection to `aus5.mozilla.org` carrying coarse version/OS/locale only. That
> is the one intentional, documented exchange — disable the updater for a fully
> silent build.

## D. Fingerprint surface

Visit a fingerprinting tester (e.g. `coveryourtracks.eff.org` or
`browserleaks.com`) and confirm:

- User agent, timezone, and screen size are **normalized** (not your real ones).
- Canvas/WebGL/audio hashes are randomized or generic.
- `navigator.hardwareConcurrency` reports a spoofed core count.
- WebRTC does **not** reveal your local LAN IP.

## E. Reproducibility

Because every layer is plain text in this repo, anyone can diff Sanctum against
upstream Firefox and a packaged build against the source. Nothing is hidden in an
obfuscated config: `autoconfig/mozilla.cfg` ships unobscured
(`general.config.obscure_value=0`) precisely so it can be read and verified.
