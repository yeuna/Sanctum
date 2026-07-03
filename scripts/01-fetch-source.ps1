# =============================================================================
#  Sanctum build — step 1: fetch the Firefox source
# -----------------------------------------------------------------------------
#  Clones Mozilla's Git monorepo at the pinned ESR ref into firefox-src/.
#  Re-running fetches updates instead of re-cloning.
# =============================================================================
param(
    [string]$SourceRef = $null,     # override the branch/tag (default: esr140)
    [switch]$Shallow = $true        # shallow clone saves ~6 GB of history
)
. (Join-Path $PSScriptRoot "lib\common.ps1")

if ($SourceRef) { $Sanctum.SourceRef = $SourceRef }

Write-Step "Fetching Firefox source ($($Sanctum.SourceRepo) @ $($Sanctum.SourceRef))"

$git = (Get-Command git -ErrorAction SilentlyContinue)
if (-not $git) { Die "git not found on PATH. Install Git for Windows (or use the one bundled in MozillaBuild)." }

if (Test-Path (Join-Path $SrcDir ".git")) {
    Write-Ok "Existing checkout found at $SrcDir — updating."
    Push-Location $SrcDir
    try {
        # Persistent checkouts (self-hosted runners) still carry the previous
        # run's overlay edits; reset tracked files so checkout succeeds and
        # patches re-apply cleanly. Untracked files (branding, obj-sanctum)
        # survive, which keeps incremental builds and the compile cache warm.
        git reset --hard HEAD
        git fetch --tags origin $Sanctum.SourceRef
        git checkout $Sanctum.SourceRef
        git pull --ff-only origin $Sanctum.SourceRef 2>$null
    } finally { Pop-Location }
} else {
    $depth = if ($Shallow) { "--depth 1" } else { "" }
    Write-Host "  Cloning into $SrcDir (this is large; expect 5-15 min)..."
    $branchArg = "--branch $($Sanctum.SourceRef)"
    $cmd = "git clone $depth $branchArg `"$($Sanctum.SourceRepo)`" `"$SrcDir`""
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Warn2 "Branch '$($Sanctum.SourceRef)' not found; cloning default branch instead."
        Invoke-Expression "git clone $depth `"$($Sanctum.SourceRepo)`" `"$SrcDir`""
    }
}

Assert-SourceCheckout
Push-Location $SrcDir
$rev = git rev-parse --short HEAD
Pop-Location
Write-Ok "Source ready at $SrcDir (HEAD $rev)"
Write-Step "Fetch complete"
