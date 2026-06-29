# =============================================================================
#  Sanctum — one-shot build orchestrator
# -----------------------------------------------------------------------------
#  Runs the whole pipeline:  fetch -> bootstrap -> overlay -> build -> package.
#  Safe to re-run; each step is idempotent. First run takes ~1-2 hours.
#
#  Examples:
#    powershell -ExecutionPolicy Bypass -File scripts\build-all.ps1
#    powershell -File scripts\build-all.ps1 -SourceRef esr140 -Jobs 16
#    powershell -File scripts\build-all.ps1 -SkipFetch -SkipBootstrap
# =============================================================================
param(
    [string]$SourceRef = "esr140",
    [int]$Jobs = 0,
    [switch]$SkipFetch,
    [switch]$SkipBootstrap,
    [switch]$SkipPackage
)
. (Join-Path $PSScriptRoot "lib\common.ps1")

$steps = @()
if (-not $SkipFetch)     { $steps += @{ name="fetch";     file="01-fetch-source.ps1";  args=@{ SourceRef=$SourceRef } } }
if (-not $SkipBootstrap) { $steps += @{ name="bootstrap"; file="00-bootstrap.ps1";     args=@{} } }
$steps += @{ name="overlay"; file="02-apply-overlay.ps1"; args=@{} }
$steps += @{ name="build";   file="03-build.ps1";         args=@{ Jobs=$Jobs } }
if (-not $SkipPackage)   { $steps += @{ name="package";   file="04-package.ps1";        args=@{} } }

Write-Step "Sanctum full build — $($steps.Count) steps"
$start = Get-Date
foreach ($s in $steps) {
    Write-Host "`n#################### $($s.name.ToUpper()) ####################" -ForegroundColor Magenta
    $stepScript = Join-Path $PSScriptRoot $s.file
    $splat = $s.args            # hashtable splat must use @<variable-name>
    & $stepScript @splat
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Die "Step '$($s.name)' failed." }
}
$elapsed = (Get-Date) - $start
Write-Step ("All done in {0:hh\:mm\:ss}. Output in {1}\dist" -f $elapsed, $RepoRoot)
