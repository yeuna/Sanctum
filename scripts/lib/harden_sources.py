#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
"""
Sanctum source surgeon / auditor.

Two jobs, both idempotent:

  apply   Bake Sanctum's default prefs into the Firefox source tree by appending
          prefs/sanctum.js to browser/app/profile/firefox.js (guarded by a
          marker so re-running never duplicates).

  audit   Determine the EFFECTIVE compiled default of each known phone-home
          preference (last assignment wins, with the app profile overriding the
          toolkit defaults) and fail if any is still "live". Because our prefs
          are appended LAST to firefox.js, a correct overlay always passes; if
          the overlay is missing or was reverted, the upstream live value is the
          effective one and the audit fails. Exit code is non-zero on any live
          finding, so CI can gate on it.

Usage:
  python harden_sources.py apply  --src <FIREFOX_SRC> --overlay <SANCTUM_ROOT>
  python harden_sources.py audit  --src <FIREFOX_SRC>
"""
import argparse
import os
import re
import sys

MARKER = "/* === SANCTUM PRIVACY DEFAULTS (appended by harden_sources.py) === */"

# Files that contribute to the compiled default pref set, in increasing
# precedence (later files override earlier ones). The app profile (firefox.js)
# wins over the toolkit-wide all.js / StaticPrefList.
PREF_FILES_IN_PRECEDENCE = [
    ("modules", "StaticPrefList.yaml"),   # lowest precedence (informational)
    ("modules", "all.js"),
    ("profile", "firefox.js"),            # highest precedence (where we append)
]

# pref name -> predicate(value_str) returning True when the value is "live"
# (i.e. capable of transmitting data). value_str is the literal as written.
def _is_live_url(v):
    return bool(v) and v not in ("", "data:,") and not v.startswith("data:")

WATCH = {
    "toolkit.telemetry.server":                        ("url",  _is_live_url),
    "app.normandy.api_url":                             ("url",  lambda v: v.startswith("http")),
    "breakpad.reportURL":                              ("url",  lambda v: v.startswith("http")),
    "media.gmp-manager.url":                            ("url",  _is_live_url),
    "toolkit.coverage.endpoint.base":                  ("url",  lambda v: v.startswith("http")),
    "datareporting.policy.dataSubmissionEnabled":      ("bool", lambda v: v == "true"),
    "datareporting.healthreport.uploadEnabled":        ("bool", lambda v: v == "true"),
    "toolkit.telemetry.unified":                       ("bool", lambda v: v == "true"),
    "toolkit.telemetry.enabled":                       ("bool", lambda v: v == "true"),
    "browser.ping-centre.telemetry":                   ("bool", lambda v: v == "true"),
    "network.captive-portal-service.enabled":          ("bool", lambda v: v == "true"),
    "network.connectivity-service.enabled":            ("bool", lambda v: v == "true"),
    "app.shield.optoutstudies.enabled":                ("bool", lambda v: v == "true"),
    "app.normandy.enabled":                            ("bool", lambda v: v == "true"),
}

# Matches:  pref("name", "value")  |  pref("name", true)  |  pref("name", 5)
PREF_RE = re.compile(
    r'pref\(\s*"([^"]+)"\s*,\s*(?:"([^"]*)"|([A-Za-z0-9_.\-]+))\s*\)'
)


def _walk_pref_values(src):
    """Return {prefname: effective_value_str} honouring file precedence + order."""
    effective = {}
    for sub, fname in PREF_FILES_IN_PRECEDENCE:
        # find the file(s); StaticPrefList is YAML (skip value parsing there)
        for root, _dirs, files in os.walk(src):
            if os.sep + "obj-" in root or os.sep + ".git" in root:
                continue
            if fname in files and (sub in root or sub == ""):
                path = os.path.join(root, fname)
                if fname.endswith(".yaml"):
                    continue  # YAML static defaults: not parsed (informational tier)
                try:
                    text = open(path, "r", encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                for m in PREF_RE.finditer(text):
                    name = m.group(1)
                    if name not in WATCH:
                        continue
                    val = m.group(2) if m.group(2) is not None else m.group(3)
                    effective[name] = val  # later file / later line overrides
    return effective


def cmd_apply(src, overlay):
    target = os.path.join(src, "browser", "app", "profile", "firefox.js")
    prefs = os.path.join(overlay, "prefs", "sanctum.js")
    if not os.path.isfile(target):
        sys.exit(f"ERROR: cannot find {target} — is --src a Firefox checkout?")
    if not os.path.isfile(prefs):
        sys.exit(f"ERROR: cannot find {prefs} — is --overlay the Sanctum repo root?")

    body = open(target, "r", encoding="utf-8", errors="replace").read()
    if MARKER in body:
        body = body.split(MARKER, 1)[0].rstrip() + "\n"
        print("note: existing Sanctum block found — refreshing it.")

    addition = open(prefs, "r", encoding="utf-8", errors="replace").read()
    with open(target, "w", encoding="utf-8") as fh:
        fh.write(body)
        fh.write("\n" + MARKER + "\n")
        fh.write(addition)
        fh.write("\n/* === end SANCTUM PRIVACY DEFAULTS === */\n")
    print("OK: appended sanctum.js into browser/app/profile/firefox.js")


def cmd_audit(src):
    effective = _walk_pref_values(src)
    findings = []
    for name, (_kind, is_live) in WATCH.items():
        if name in effective and is_live(effective[name]):
            findings.append((name, effective[name]))

    if findings:
        print("FAIL: live data-collection defaults still in effect:")
        for name, val in findings:
            print(f'  {name} = {val!r}')
        sys.exit(1)
    checked = sum(1 for n in WATCH if n in effective)
    print(f"PASS: no live telemetry/phone-home default remains "
          f"({checked} watched prefs evaluated, all safe).")


def main():
    ap = argparse.ArgumentParser(description="Sanctum source surgeon / auditor")
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("apply", help="append Sanctum prefs into the source tree")
    a.add_argument("--src", required=True)
    a.add_argument("--overlay", required=True)
    au = sub.add_parser("audit", help="evaluate effective phone-home defaults")
    au.add_argument("--src", required=True)
    args = ap.parse_args()

    if args.cmd == "apply":
        cmd_apply(os.path.abspath(args.src), os.path.abspath(args.overlay))
    elif args.cmd == "audit":
        cmd_audit(os.path.abspath(args.src))


if __name__ == "__main__":
    main()
