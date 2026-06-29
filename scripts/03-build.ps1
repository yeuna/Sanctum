# =============================================================================
#  Sanctum build — step 3: compile
# -----------------------------------------------------------------------------
#  Runs `mach build`. Expect 30-90 min on first build depending on cores/RAM.
#  Then drops the locked autoconfig + policy files into dist/bin so that
#  `mach run` exercises the SAME privacy guarantees as the packaged installer.
# =============================================================================
param([int]$Jobs = 0)   # 0 = use all cores (mozconfig default)
. (Join-Path $PSScriptRoot "lib\common.ps1")
Assert-SourceCheckout

if (-not (Test-Path (Join-Path $SrcDir ".mozconfig"))) {
    Die "No .mozconfig in the checkout. Run scripts/02-apply-overlay.ps1 first."
}

Write-Step "Compiling Sanctum (mach build)"
if ($Jobs -gt 0) { Invoke-Mach "build -j$Jobs" } else { Invoke-Mach "build" }
Write-Ok "build finished"

# Install the runtime privacy layers into the just-built binary dir so that
# './mach run' and packaging both see them.
Write-Step "Installing autoconfig + policy layers into dist/bin"
$distBin = Join-Path $SrcDir ($Sanctum.ObjDir + "\dist\bin")
if (-not (Test-Path $distBin)) {
    # objdir may be flat depending on config; fall back to a search.
    $found = Get-ChildItem $SrcDir -Recurse -Directory -Filter "bin" -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -match "dist\\bin$" } | Select-Object -First 1
    if ($found) { $distBin = $found.FullName }
}
if (Test-Path $distBin) {
    New-Item -ItemType Directory -Force -Path (Join-Path $distBin "defaults\pref") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $distBin "distribution") | Out-Null
    Copy-Item (Join-Path $RepoRoot "autoconfig\mozilla.cfg")        (Join-Path $distBin "mozilla.cfg") -Force
    Copy-Item (Join-Path $RepoRoot "autoconfig\autoconfig.js")      (Join-Path $distBin "defaults\pref\autoconfig.js") -Force
    Copy-Item (Join-Path $RepoRoot "distribution\policies.json")    (Join-Path $distBin "distribution\policies.json") -Force
    Write-Ok "mozilla.cfg + autoconfig.js + policies.json installed into $distBin"
} else {
    Write-Warn2 "Could not locate dist/bin; run will lack locked layers (package step will still install them)."
}

Write-Step "Build complete — test with:  cd $SrcDir ; ./mach run"
