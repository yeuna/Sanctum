# =============================================================================
#  Sanctum build — shared configuration & helpers (dot-sourced by every step)
# =============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------- identity
$Global:Sanctum = [ordered]@{
    Name        = "Sanctum"
    BrandingDir = "sanctum"                       # browser/branding/<this>
    AppName     = "sanctum"
    ObjDir      = "obj-sanctum"                    # must match mozconfig MOZ_OBJDIR

    # Upstream Firefox source. Mozilla's canonical repo is now the Git monorepo.
    # Pin to an ESR line for stability; override with -SourceRef on 01-fetch.
    SourceRepo  = "https://github.com/mozilla-firefox/firefox.git"
    SourceRef   = "esr140"                         # branch or tag to build
}

# ------------------------------------------------------------------- paths
# Repo root = parent of the scripts/ directory that contains this file.
$Global:RepoRoot   = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Global:ScriptsDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Where the Firefox checkout lives. Override with env SANCTUM_SRC.
if ($env:SANCTUM_SRC) { $Global:SrcDir = $env:SANCTUM_SRC }
else { $Global:SrcDir = Join-Path $RepoRoot "firefox-src" }

# MozillaBuild (provides msys2 bash + unix tooling mach needs on Windows).
if ($env:MOZILLABUILD) { $Global:MozillaBuild = $env:MOZILLABUILD }
else { $Global:MozillaBuild = "C:\mozilla-build" }

# ------------------------------------------------------------------ logging
function Write-Step($msg)  { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  [ok] $msg"   -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  [!!] $msg"   -ForegroundColor Yellow }
function Die($msg)         { Write-Host "  [xx] $msg"   -ForegroundColor Red; exit 1 }

# ----------------------------------------------------------- mach invocation
# mach on Windows needs the MozillaBuild msys2 environment (bash, awk, make...).
# We run each mach command through that bash so the toolchain is correct.
function Get-Bash {
    $candidates = @(
        (Join-Path $MozillaBuild "msys2\usr\bin\bash.exe"),
        (Join-Path $MozillaBuild "msys\bin\bash.exe")
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    Die "Could not find MozillaBuild bash. Install MozillaBuild and/or set `$env:MOZILLABUILD. Looked in: $($candidates -join ', ')"
}

# Convert a Windows path to an msys2 path:  C:\a\b  ->  /c/a/b
function ConvertTo-MsysPath($winPath) {
    $p = (Resolve-Path $winPath).Path
    $p = $p -replace '\\', '/'
    if ($p -match '^([A-Za-z]):/(.*)$') { return "/$($matches[1].ToLower())/$($matches[2])" }
    return $p
}

# Run a mach subcommand inside the source dir via MozillaBuild bash.
function Invoke-Mach {
    param([Parameter(Mandatory)][string]$Args)
    $bash = Get-Bash
    $srcMsys = ConvertTo-MsysPath $SrcDir
    $cmd = "cd '$srcMsys' && ./mach $Args"
    Write-Host "  > mach $Args" -ForegroundColor DarkGray
    & $bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { Die "mach $Args failed (exit $LASTEXITCODE)" }
}

function Assert-SourceCheckout {
    if (-not (Test-Path (Join-Path $SrcDir "mach"))) {
        Die "No Firefox checkout at $SrcDir. Run scripts/01-fetch-source.ps1 first (or set `$env:SANCTUM_SRC)."
    }
}

# ----------------------------------------------------------- code signing
# Authenticode signing is OPTIONAL. It activates only when a certificate is
# provided through one of these environment variables (e.g. GitHub secrets):
#   SANCTUM_SIGN_PFX_BASE64    base64 of a .pfx/.p12 file  (+ SANCTUM_SIGN_PFX_PASSWORD)
#   SANCTUM_SIGN_PFX_PATH      path to a .pfx on disk      (+ SANCTUM_SIGN_PFX_PASSWORD)
#   SANCTUM_SIGN_THUMBPRINT    SHA1 thumbprint of a cert already in the cert store
# Optional: SANCTUM_SIGN_TIMESTAMP_URL (default DigiCert RFC3161 timestamp).
# If none are set, binaries are left UNSIGNED and the build still succeeds.

function Test-SigningConfigured {
    return [bool]($env:SANCTUM_SIGN_PFX_BASE64 -or $env:SANCTUM_SIGN_PFX_PATH -or $env:SANCTUM_SIGN_THUMBPRINT)
}

function Get-SignTool {
    # Newest x64 signtool.exe from the Windows SDK wins.
    $roots = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
        "$env:ProgramFiles\Windows Kits\10\bin"
    )
    $cands = @()
    foreach ($r in $roots) {
        if (Test-Path $r) {
            $cands += Get-ChildItem $r -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
                      Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' }
        }
    }
    $st = $cands | Sort-Object FullName -Descending | Select-Object -First 1
    if ($st) { return $st.FullName }
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

# Sign one or more files. No-op (with a warning) if signing isn't configured.
function Invoke-CodeSign {
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Files)

    $Files = @($Files | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique)
    if ($Files.Count -eq 0) { return }

    if (-not (Test-SigningConfigured)) {
        Write-Warn2 "No signing certificate configured (SANCTUM_SIGN_*) — leaving $($Files.Count) file(s) UNSIGNED."
        return
    }
    $signtool = Get-SignTool
    if (-not $signtool) { Write-Warn2 "signtool.exe not found (install the Windows SDK) — skipping signing."; return }

    $ts = if ($env:SANCTUM_SIGN_TIMESTAMP_URL) { $env:SANCTUM_SIGN_TIMESTAMP_URL } else { "http://timestamp.digicert.com" }

    $pfxPath = $null; $cleanup = $false
    if ($env:SANCTUM_SIGN_PFX_BASE64) {
        $pfxPath = Join-Path $env:TEMP ("sanctum-" + [guid]::NewGuid().ToString('N') + ".pfx")
        [IO.File]::WriteAllBytes($pfxPath, [Convert]::FromBase64String($env:SANCTUM_SIGN_PFX_BASE64))
        $cleanup = $true
    } elseif ($env:SANCTUM_SIGN_PFX_PATH) {
        $pfxPath = $env:SANCTUM_SIGN_PFX_PATH
    }

    Write-Host "  signing $($Files.Count) file(s) with $signtool" -ForegroundColor DarkGray
    try {
        foreach ($f in $Files) {
            $a = @("sign", "/fd", "SHA256", "/tr", $ts, "/td", "SHA256")
            if ($pfxPath) {
                $a += @("/f", $pfxPath)
                if ($env:SANCTUM_SIGN_PFX_PASSWORD) { $a += @("/p", $env:SANCTUM_SIGN_PFX_PASSWORD) }
            } elseif ($env:SANCTUM_SIGN_THUMBPRINT) {
                $a += @("/sha1", $env:SANCTUM_SIGN_THUMBPRINT)
            }
            $a += $f
            & $signtool @a
            if ($LASTEXITCODE -ne 0) { Die "signtool failed on $f (exit $LASTEXITCODE)" }
            Write-Ok ("signed " + (Split-Path $f -Leaf))
        }
    } finally {
        if ($cleanup -and $pfxPath -and (Test-Path $pfxPath)) { Remove-Item $pfxPath -Force }
    }
}
