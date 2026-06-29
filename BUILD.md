# Building Sanctum on Windows

This guide takes you from a clean Windows machine to a packaged Sanctum build.

## 1. Prerequisites

| Requirement | Notes |
|---|---|
| **Windows 10/11 (64-bit)** | A 64-bit OS is required to build the 64-bit browser. |
| **RAM** | 8 GB minimum; 16 GB+ strongly recommended. LTO/PGO (optional) wants 32 GB. |
| **Disk** | ~40 GB free: source tree (~5 GB shallow), object dir, and toolchain. |
| **Visual Studio 2022** | Install the **"Desktop development with C++"** workload, plus the latest **Windows 11 SDK** and the **ATL/MFC** components. The Community edition is free and sufficient. |
| **MozillaBuild** | Provides the msys2 shell, `make`, `python`, and the unix tools `mach` needs on Windows. Install to the default `C:\mozilla-build`. Download: <https://ftp.mozilla.org/pub/mozilla/libraries/win32/MozillaBuildSetup-Latest.exe> |
| **Git** | Git for Windows, or the copy bundled inside MozillaBuild. |

> Put `C:\mozilla-build` **before** any Cygwin directories on your `PATH`, or
> the wrong `sh`/`awk` may be picked up and the build will fail.

## 2. Get this repository

You already have it — it's the folder containing this file. All paths below are
relative to that folder (the repo root).

## 3. One-command build

Open **PowerShell** (a normal Windows PowerShell window is fine — the scripts
hand the heavy lifting to the MozillaBuild shell automatically) in the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-all.ps1 -SourceRef esr140
```

Steps the orchestrator runs, in order:

1. **fetch** — shallow-clones Firefox ESR source into `firefox-src\`.
2. **bootstrap** — `mach bootstrap` pulls clang/rust/nasm and the rest of the toolchain.
3. **overlay** — installs the mozconfig + branding, bakes in `prefs/sanctum.js`, applies any patches, then **audits** the tree for surviving telemetry endpoints.
4. **build** — `mach build` (30–90 min on first run).
5. **package** — emits `dist\Sanctum-<rev>-win64.zip` (portable) and, when NSIS is available, `dist\Sanctum-<rev>-win64.installer.exe`.

Useful flags:

```powershell
# pick the source line / parallelism
scripts\build-all.ps1 -SourceRef esr140 -Jobs 16

# re-build without re-fetching or re-bootstrapping
scripts\build-all.ps1 -SkipFetch -SkipBootstrap

# build only, skip packaging
scripts\build-all.ps1 -SkipPackage
```

## 4. Running step-by-step (recommended the first time)

```powershell
scripts\01-fetch-source.ps1 -SourceRef esr140
scripts\00-bootstrap.ps1
scripts\02-apply-overlay.ps1
scripts\03-build.ps1 -Jobs 16
scripts\04-package.ps1
```

After `03-build.ps1`, smoke-test the binary from the MozillaBuild shell:

```bash
cd firefox-src
./mach run
```

Then open `about:config` and confirm the locked prefs (e.g.
`datareporting.policy.dataSubmissionEnabled`) show the **lock icon** and cannot
be changed, and `about:policies` shows the Sanctum policy set as **active**.

## 5. Choosing the source line

`-SourceRef` accepts any branch or tag of Mozilla's Git monorepo
(`github.com/mozilla-firefox/firefox`):

| Value | Meaning |
|---|---|
| `esr140` | The current Extended Support Release line (recommended — fewer churned prefs, security-only updates). |
| `release` | The latest stable Firefox line. |
| `FIREFOX_140_2_0esr_RELEASE` | A specific pinned tag (most reproducible). |

If a ref isn't found, the fetch script falls back to the repository's default
branch and tells you.

## 6. Common issues

| Symptom | Fix |
|---|---|
| `Could not find MozillaBuild bash` | Install MozillaBuild, or set `$env:MOZILLABUILD` to its path. |
| `configure: error: ... Visual C++` | Install the VS 2022 "Desktop development with C++" workload + Windows SDK. |
| Build uses Cygwin tools and dies | Move `C:\mozilla-build\...` ahead of Cygwin on `PATH`. |
| Out of memory during linking | Lower `-Jobs`, or comment out the LTO/PGO lines in `mozconfig`. |
| `AUDIT FAILED` in the overlay step | A live telemetry endpoint slipped in — `scripts\lib\harden_sources.py audit --src firefox-src` prints exactly which file/line; fix it before building. |

## 7. Output

Everything lands in `dist\`:

- `Sanctum-<rev>-win64.zip` — unzip and run `sanctum.exe`; fully portable, carries all four privacy layers.
- `Sanctum-<rev>-win64.installer.exe` — standard Windows installer (built when NSIS is present); installs **without** registering any scheduled task.
