# =============================================================================
#  Sanctum build — step 5 (optional): sign artifacts in dist/
# -----------------------------------------------------------------------------
#  Packaging (04) already signs in-place when a cert is configured. Use THIS
#  script to (re)sign artifacts after the fact — e.g. to sign installers that
#  were built on a runner without access to the signing cert, on a separate
#  secured machine that holds the certificate.
#
#  Configure a certificate via environment (see scripts/lib/common.ps1):
#    $env:SANCTUM_SIGN_PFX_PATH = "C:\path\to\cert.pfx"
#    $env:SANCTUM_SIGN_PFX_PASSWORD = "..."
#  ...or SANCTUM_SIGN_PFX_BASE64, or SANCTUM_SIGN_THUMBPRINT.
#
#  Examples:
#    scripts\05-sign.ps1                      # sign everything in dist\
#    scripts\05-sign.ps1 -Path dist\Sanctum-abc123-win64.installer.exe
# =============================================================================
param(
    [string]$Path = $null   # a file or folder; default: the repo's dist\ folder
)
. (Join-Path $PSScriptRoot "lib\common.ps1")

if (-not (Test-SigningConfigured)) {
    Die "No signing certificate configured. Set SANCTUM_SIGN_PFX_PATH (+ _PASSWORD), SANCTUM_SIGN_PFX_BASE64, or SANCTUM_SIGN_THUMBPRINT first."
}

if (-not $Path) { $Path = Join-Path $RepoRoot "dist" }
if (-not (Test-Path $Path)) { Die "Nothing to sign at $Path (build/package first)." }

Write-Step "Signing artifacts under $Path"
$item = Get-Item $Path
if ($item.PSIsContainer) {
    $files = Get-ChildItem $Path -Recurse -Include *.exe, *.dll, *.msi -ErrorAction SilentlyContinue |
             Select-Object -ExpandProperty FullName
} else {
    $files = @($item.FullName)
}

if (-not $files) { Write-Warn2 "No signable files (.exe/.dll/.msi) found under $Path."; exit 0 }
Invoke-CodeSign -Files $files
Write-Step "Signing complete ($($files.Count) file(s))"
