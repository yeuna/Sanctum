# =============================================================================
#  Sanctum build — step 0: bootstrap the build environment
# -----------------------------------------------------------------------------
#  Checks the Windows prerequisites and runs `mach bootstrap` to pull the
#  Firefox toolchain (clang, rust, nasm, etc.). Run this once per machine.
# =============================================================================
. (Join-Path $PSScriptRoot "lib\common.ps1")

Write-Step "Sanctum bootstrap — checking prerequisites"

# --- MozillaBuild --------------------------------------------------------
if (-not (Test-Path $MozillaBuild)) {
    Write-Warn2 "MozillaBuild not found at $MozillaBuild"
    Write-Host  "  Download & install it (provides msys2/bash/make/python that mach needs):"
    Write-Host  "    https://ftp.mozilla.org/pub/mozilla/libraries/win32/MozillaBuildSetup-Latest.exe"
    Die "Install MozillaBuild, then re-run. Set `$env:MOZILLABUILD if you used a custom path."
}
Write-Ok "MozillaBuild present: $MozillaBuild"

# --- Visual Studio + Windows SDK ----------------------------------------
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property displayName 2>$null
    if ($vs) { Write-Ok "Visual Studio C++ toolset: $vs" }
    else { Write-Warn2 "Visual Studio found but the 'Desktop development with C++' workload may be missing." }
} else {
    Write-Warn2 "Visual Studio not detected. Install VS 2022 with 'Desktop development with C++' + Windows 10/11 SDK."
}

# --- Disk space ----------------------------------------------------------
$drive = (Get-Item $RepoRoot).PSDrive
$freeGB = [math]::Round(($drive.Free) / 1GB, 1)
if ($freeGB -lt 40) { Write-Warn2 "Only $freeGB GB free on $($drive.Name): — a full build needs ~40 GB." }
else { Write-Ok "$freeGB GB free on $($drive.Name): (>= 40 GB recommended)" }

# --- mach bootstrap ------------------------------------------------------
if (Test-Path (Join-Path $SrcDir "mach")) {
    Write-Step "Running 'mach bootstrap' (Firefox for Desktop, artifact mode OFF)"
    # '--application-choice browser' = Firefox for Desktop; supplying it is what
    # makes bootstrap non-interactive (it skips the app-selection prompt).
    # '--no-system-changes' keeps bootstrap from trying interactive system tweaks.
    Invoke-Mach "bootstrap --application-choice browser --no-system-changes"
    Write-Ok "Toolchain bootstrapped."
} else {
    Write-Warn2 "No source checkout yet — skipping 'mach bootstrap'."
    Write-Host  "  Run scripts/01-fetch-source.ps1 first, then re-run this script to bootstrap the toolchain."
}

Write-Step "Bootstrap complete"
