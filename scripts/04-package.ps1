# =============================================================================
#  Sanctum build — step 4: package a distributable
# -----------------------------------------------------------------------------
#  Runs `mach package`, injects the locked autoconfig + policy layers into the
#  packaged application, signs the binaries (if a cert is configured), then
#  emits a portable ZIP and, if NSIS is available, a Windows installer .exe.
#  The injected files are what guarantee the shipped build cannot be made to
#  phone home.
# =============================================================================
. (Join-Path $PSScriptRoot "lib\common.ps1")
Assert-SourceCheckout

Write-Step "Packaging (mach package)"
Invoke-Mach "package"

# --- locate the packaged application staging directory -------------------
$distRoot = Join-Path $SrcDir ($Sanctum.ObjDir + "\dist")
$appDir = $null
foreach ($n in @($Sanctum.AppName, "sanctum", "firefox")) {
    $cand = Join-Path $distRoot $n
    if (Test-Path (Join-Path $cand "$($Sanctum.AppName).exe")) { $appDir = $cand; break }
    if (Test-Path (Join-Path $cand "firefox.exe"))             { $appDir = $cand; break }
}
if (-not $appDir) {
    $exe = Get-ChildItem $distRoot -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -in @("$($Sanctum.AppName).exe", "firefox.exe") } | Select-Object -First 1
    if ($exe) { $appDir = $exe.Directory.FullName }
}
if (-not $appDir) { Die "Could not find packaged app under $distRoot" }
Write-Ok "packaged app: $appDir"

# --- inject the locked privacy layers ------------------------------------
Write-Step "Injecting locked autoconfig + policies into the package"
New-Item -ItemType Directory -Force -Path (Join-Path $appDir "defaults\pref") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $appDir "distribution") | Out-Null
Copy-Item (Join-Path $RepoRoot "autoconfig\mozilla.cfg")     (Join-Path $appDir "mozilla.cfg") -Force
Copy-Item (Join-Path $RepoRoot "autoconfig\autoconfig.js")   (Join-Path $appDir "defaults\pref\autoconfig.js") -Force
Copy-Item (Join-Path $RepoRoot "distribution\policies.json") (Join-Path $appDir "distribution\policies.json") -Force
Write-Ok "mozilla.cfg, defaults/pref/autoconfig.js, distribution/policies.json injected"

# --- sign the application binaries (optional; before zipping) -------------
Write-Step "Signing application binaries"
$exes = Get-ChildItem $appDir -Recurse -Filter *.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
if ($env:SANCTUM_SIGN_ALL -eq "1") {
    # Sign every bundled DLL too (slower, fully signed package).
    $dlls = Get-ChildItem $appDir -Recurse -Filter *.dll -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    Invoke-CodeSign -Files (@($exes) + @($dlls))
} else {
    # Default: sign the executables. Set SANCTUM_SIGN_ALL=1 to also sign DLLs.
    Invoke-CodeSign -Files $exes
}

# --- emit a portable ZIP -------------------------------------------------
Write-Step "Creating portable ZIP"
$outDir = Join-Path $RepoRoot "dist"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Push-Location $SrcDir
$rev = git rev-parse --short HEAD
Pop-Location
$zip = Join-Path $outDir ("Sanctum-{0}-win64.zip" -f $rev)
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $appDir "*") -DestinationPath $zip
Write-Ok "portable build -> $zip"

# --- optional NSIS installer --------------------------------------------
Write-Step "Building Windows installer (mach repackage installer)"
try {
    Invoke-Mach "repackage installer"
    $inst = Get-ChildItem $distRoot -Recurse -Filter "*.installer.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($inst) {
        $instOut = Join-Path $outDir ("Sanctum-{0}-win64.installer.exe" -f $rev)
        Copy-Item $inst.FullName $instOut -Force
        Invoke-CodeSign -Files @($instOut)   # sign the installer itself
        Write-Ok "installer -> dist/Sanctum-$rev-win64.installer.exe"
    } else {
        Write-Warn2 "Installer target produced no .exe; the portable ZIP is fully usable."
    }
} catch {
    Write-Warn2 "Installer step skipped/failed; portable ZIP is the deliverable. ($_)"
}

Write-Step "Packaging complete -> $outDir"
