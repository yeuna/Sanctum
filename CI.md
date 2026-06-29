# Continuous builds & code signing

`.github/workflows/build.yml` builds Sanctum from Firefox source on a Windows
runner and publishes a portable ZIP, a Windows installer, and a
`SHA256SUMS.txt`. Code signing is automatic **if** you add a certificate; without
one the build still succeeds and ships unsigned artifacts.

## Triggering a build

- **Manually:** GitHub → **Actions** → *Build Sanctum (Windows)* → **Run workflow**. You can set the Firefox `source_ref` (default `esr140`) and whether to sign every bundled DLL.
- **By tag:** push a tag like `v1.0` — the workflow builds and attaches the artifacts to a new **GitHub Release**.

```bash
git tag v1.0
git push origin v1.0
```

## What the pipeline does

1. Installs **MozillaBuild** (the msys2 toolchain `mach` needs on Windows).
2. Starts **sccache** and restores the cached toolchain (`.mozbuild`) to speed up repeat builds.
3. Runs the same scripts you run locally: `01-fetch` → `00-bootstrap` → `02-apply-overlay` (which **audits** the tree and fails the build if any live telemetry endpoint survives) → `03-build` → `04-package`.
4. Signs the executables (and the installer) when a cert is configured.
5. Uploads artifacts and, on a tag, creates a Release with auto-generated notes.

The `windows-2022` runner already has Visual Studio 2022 (C++), the Windows SDK,
Git, and Python — nothing else to install.

## Enabling code signing (Authenticode)

Add these as **repository secrets** (Settings → Secrets and variables → Actions):

| Secret | Meaning |
|---|---|
| `SANCTUM_SIGN_PFX_BASE64` | Your code-signing certificate (`.pfx`/`.p12`), base64-encoded. |
| `SANCTUM_SIGN_PFX_PASSWORD` | The password for that `.pfx`. |

Optionally set a repository **variable** `SANCTUM_SIGN_TIMESTAMP_URL` to override
the default RFC-3161 timestamp server (`http://timestamp.digicert.com`).

Encode your `.pfx` to base64:

```powershell
# Windows / PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\cert.pfx")) | Set-Content cert.b64
```
```bash
# macOS / Linux
base64 -w0 cert.pfx > cert.b64
```

Paste the contents of `cert.b64` into the `SANCTUM_SIGN_PFX_BASE64` secret.

The signer (`scripts/lib/common.ps1 → Invoke-CodeSign`) uses `signtool` with
SHA-256 and an RFC-3161 timestamp, so signatures stay valid after the cert
expires. It activates only when a secret is present; otherwise it logs a warning
and continues, leaving artifacts unsigned.

### Signing locally instead

If you prefer to keep the certificate off GitHub, build unsigned in CI, then sign
on a secured machine that holds the cert:

```powershell
$env:SANCTUM_SIGN_PFX_PATH = "C:\secure\cert.pfx"
$env:SANCTUM_SIGN_PFX_PASSWORD = "..."
scripts\05-sign.ps1 -Path .\dist
```

### Alternative: Azure Trusted Signing / cloud HSM

For keys that never touch disk, swap `Invoke-CodeSign` for Azure Trusted Signing
(`azure/trusted-signing-action`) or a cloud-HSM `signtool` with the
`/dlib` Azure Key Vault dispenser. The four-layer privacy design is unaffected —
signing only proves provenance; it does not change browser behavior.

## A note on build resources (important)

A full Firefox compile is heavy: ~40 GB of disk and 1–3 hours even with sccache.
GitHub-hosted runners have a **6-hour job cap** and finite disk, so the first
(cold-cache) run can be tight. For reliable, faster builds:

- **Use a self-hosted runner** (a beefy Windows box or a large cloud VM with ≥ 32 GB RAM, 8+ cores, 80 GB free). Label it and change `runs-on: windows-2022` to `runs-on: [self-hosted, windows, x64]`.
- Or switch to GitHub's **larger hosted runners** (more cores/disk) on a paid plan.

sccache makes subsequent builds dramatically faster because unchanged objects
are reused across runs.

## Verifying published artifacts

```powershell
# integrity
Get-FileHash .\Sanctum-<rev>-win64.installer.exe -Algorithm SHA256
# compare against SHA256SUMS.txt

# signature (if signed)
signtool verify /pa .\Sanctum-<rev>-win64.installer.exe
```

End users should also run the checks in [VERIFY.md](VERIFY.md) — a packet capture
proving zero unsolicited network traffic is the real test, signed or not.
