# =============================================================================
#  Sanctum build — step 2: apply the privacy overlay onto the source tree
# -----------------------------------------------------------------------------
#  Idempotent. Wires Sanctum into the Firefox checkout:
#    1. install the mozconfig          -> firefox-src/.mozconfig
#    2. install custom branding         -> browser/branding/sanctum/
#    3. bake privacy prefs into defaults (harden_sources.py apply)
#    4. apply any source patches in patches/series
#    5. audit: prove no live telemetry endpoint remains
# =============================================================================
. (Join-Path $PSScriptRoot "lib\common.ps1")
Assert-SourceCheckout

function Get-Python {
    foreach ($c in @("py -3", "python", "python3")) {
        $exe = $c.Split(' ')[0]
        if (Get-Command $exe -ErrorAction SilentlyContinue) { return $c }
    }
    Die "Python not found on PATH (need it for harden_sources.py)."
}
$py = Get-Python

# --- 1. mozconfig --------------------------------------------------------
Write-Step "Installing mozconfig"
Copy-Item (Join-Path $RepoRoot "mozconfig") (Join-Path $SrcDir ".mozconfig") -Force
Write-Ok ".mozconfig installed"

# --- 2. branding ---------------------------------------------------------
Write-Step "Installing Sanctum branding"
$brandSrc = Join-Path $RepoRoot ("branding\" + $Sanctum.BrandingDir)
$brandDst = Join-Path $SrcDir ("browser\branding\" + $Sanctum.BrandingDir)

# Icons are generated (not committed) so the repo stays text-only. Regenerate
# them from geometry if a fresh checkout is missing them.
if (-not (Test-Path (Join-Path $brandSrc "default256.png"))) {
    Write-Host "  generating branding icons (pip install pillow if needed)..." -ForegroundColor DarkGray
    Invoke-Expression "$py -m pip install --quiet --disable-pip-version-check pillow"
    Invoke-Expression "$py `"$(Join-Path $brandSrc 'generate-icons.py')`""
    if (-not (Test-Path (Join-Path $brandSrc "default256.png"))) { Die "icon generation failed" }
    Write-Ok "branding icons generated"
}
if (Test-Path $brandDst) { Remove-Item $brandDst -Recurse -Force }
New-Item -ItemType Directory -Force -Path $brandDst | Out-Null
Copy-Item (Join-Path $brandSrc "*") $brandDst -Recurse -Force
Write-Ok "branding copied -> browser/branding/$($Sanctum.BrandingDir)"

# --- 3. bake privacy prefs ----------------------------------------------
Write-Step "Baking privacy default preferences into the tree"
$harden = Join-Path $ScriptsDir "lib\harden_sources.py"
Invoke-Expression "$py `"$harden`" apply --src `"$SrcDir`" --overlay `"$RepoRoot`""
if ($LASTEXITCODE -ne 0) { Die "harden_sources apply failed" }

# --- 4. source patches (optional) ---------------------------------------
$series = Join-Path $RepoRoot "patches\series"
if (Test-Path $series) {
    $patches = Get-Content $series | Where-Object { $_ -and -not $_.StartsWith("#") }
    if ($patches) {
        Write-Step "Applying $($patches.Count) source patch(es)"
        Push-Location $SrcDir
        try {
            foreach ($p in $patches) {
                $pf = Join-Path $RepoRoot ("patches\" + $p.Trim())
                Write-Host "  applying $p"
                git apply --3way --whitespace=nowarn $pf
                if ($LASTEXITCODE -ne 0) { Die "patch failed to apply: $p" }
            }
        } finally { Pop-Location }
        Write-Ok "all patches applied"
    } else { Write-Ok "no source patches listed (settings layers cover everything)" }
}

# --- 5. audit ------------------------------------------------------------
Write-Step "Auditing tree for any surviving phone-home default"
Invoke-Expression "$py `"$harden`" audit --src `"$SrcDir`""
if ($LASTEXITCODE -ne 0) { Die "AUDIT FAILED — a live telemetry endpoint is still enabled. Fix before building." }
Write-Ok "audit passed — no live data-collection default remains"

Write-Step "Overlay applied successfully"
