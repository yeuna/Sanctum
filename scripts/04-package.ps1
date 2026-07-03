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

# --- build the NSIS installer machinery (setup.exe) ----------------------
# This must run BEFORE the privacy layers are injected: the installer build
# re-stages dist/<app> from the package manifest, which would wipe any files
# we add. We only need the setup.exe it produces; the final installer is
# assembled later from the injected + signed app directory.
Write-Step "Building NSIS installer machinery (mach build installer)"
Invoke-Mach "build installer" -NonFatal
$installerBuilt = ($Global:MachExitCode -eq 0)

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
# Assemble the installer from the INJECTED + SIGNED app directory (not the
# re-staged one `mach build installer` produced), so the installer ships the
# same locked configuration as the portable ZIP. `mach repackage installer`
# wraps <package zip> + setup.exe in the 7z self-extracting NSIS stub.
Write-Step "Building Windows installer (mach repackage installer)"
$setupExe = $null
if ($installerBuilt) {
    $setupExe = Get-ChildItem (Join-Path $SrcDir ($Sanctum.ObjDir + "\browser\installer\windows")) `
                -Recurse -Filter "setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $setupExe) {
    Write-Warn2 "NSIS setup.exe not available; skipping installer. The portable ZIP is fully usable."
} else {
    Invoke-CodeSign -Files @($setupExe.FullName)

    # repackage expects a zip whose top-level directory is the app dir.
    $pkgName = Split-Path $appDir -Leaf
    $pkgZip = Join-Path $distRoot "sanctum-repack.zip"
    if (Test-Path $pkgZip) { Remove-Item $pkgZip -Force }
    Compress-Archive -Path $appDir -DestinationPath $pkgZip

    $instOut = Join-Path $outDir ("Sanctum-{0}-win64.installer.exe" -f $rev)
    $machArgs = "repackage installer" +
        " --tag browser/installer/windows/app.tag" +
        " --sfx-stub other-licenses/7zstub/firefox/7zSD.Win32.sfx" +
        " --setupexe '$($setupExe.FullName -replace '\\', '/')'" +
        " --package '$($pkgZip -replace '\\', '/')'" +
        " --package-name '$pkgName'" +
        " -o '$($instOut -replace '\\', '/')'"
    Invoke-Mach $machArgs -NonFatal
    Remove-Item $pkgZip -Force -ErrorAction SilentlyContinue

    if ($Global:MachExitCode -eq 0 -and (Test-Path $instOut)) {
        Invoke-CodeSign -Files @($instOut)   # sign the installer itself
        Write-Ok "installer -> dist/$(Split-Path $instOut -Leaf)"
    } else {
        Write-Warn2 "Installer step failed; portable ZIP is the deliverable."
    }
}

Write-Step "Packaging complete -> $outDir"
