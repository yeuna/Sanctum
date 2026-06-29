# Sanctum patch strategy

Sanctum removes data collection through **four independent layers**, applied in
this order of precedence. Most users never need to touch raw source diffs.

| Layer | Mechanism | Removes |
|---|---|---|
| 1. Compile-time | `mozconfig` build flags | Crash reporter binary, Windows default-browser agent, telemetry/data-reporting/healthreport/Normandy build defines |
| 2. Compiled-in defaults | `prefs/sanctum.js` appended to `browser/app/profile/firefox.js` by `scripts/lib/harden_sources.py apply` | Default values for every runtime phone-home / fingerprint pref |
| 3. Locked autoconfig | `autoconfig/mozilla.cfg` + `autoconfig.js` installed into the package | Freezes the "holy" switches so nothing can re-enable them |
| 4. Enterprise policy | `distribution/policies.json` | Durable, profile-proof enforcement |

Because layers 1–4 already neutralise every known endpoint, Sanctum does **not**
ship brittle line-numbered C++ diffs that break on every Firefox uplift.

## Adding your own source-level patch

If you want to change actual C++/Rust/JS source (e.g. rip an endpoint out of the
binary rather than blanking its pref), drop a unified diff here and list it in
`series`. The build runs them in order:

```
patches/
  series                      <- one patch filename per line, in apply order
  0001-my-change.patch
```

Generate a patch from your edited checkout with:

```sh
cd <firefox-src>
git diff > /path/to/sanctum/patches/0001-my-change.patch
```

`scripts/02-apply-overlay.ps1` applies every patch in `series` with
`git apply --3way` (resilient to small context drift) before building.

## Verifying

After applying the overlay, prove no live endpoint survives as a default:

```sh
python scripts/lib/harden_sources.py audit --src <firefox-src>
```

A `PASS` line means no telemetry/phone-home pref is left enabled in the
compiled defaults. CI gates on its exit code.
