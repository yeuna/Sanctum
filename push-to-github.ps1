# =============================================================================
#  Sanctum — initialize git and push this project to GitHub
# -----------------------------------------------------------------------------
#  Run this from THIS folder, on your machine (where your GitHub login lives).
#
#  Easiest (if you have the GitHub CLI `gh` installed & logged in):
#     powershell -ExecutionPolicy Bypass -File push-to-github.ps1
#
#  If you already created an empty repo on github.com:
#     powershell -File push-to-github.ps1 -RemoteUrl https://github.com/<you>/sanctum-browser.git
#
#  Options:
#     -RepoName    name of the repo to create   (default: sanctum-browser)
#     -Visibility  private | public             (default: private)
#     -RemoteUrl   push to an existing repo URL instead of creating one
# =============================================================================
param(
    [string]$RepoName = "Sanctum",
    [ValidateSet("private", "public")][string]$Visibility = "private",
    [string]$RemoteUrl = $null,
    [switch]$Force            # overwrite a freshly-created repo that already has a README commit
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Fail($m) { Write-Host "  [xx] $m" -ForegroundColor Red; exit 1 }
function Ok($m)   { Write-Host "  [ok] $m" -ForegroundColor Green }

# --- prerequisites -------------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "git is not installed. Get it from https://git-scm.com/download/win"
}
if (-not (git config user.name)) {
    Fail "No git identity set. Run:  git config --global user.name `"Your Name`"  and  git config --global user.email `"you@example.com`""
}

# --- initialize repo (idempotent) ---------------------------------------
if (-not (Test-Path ".git")) {
    git init | Out-Null
    git branch -M main
    Ok "git repository initialized (branch: main)"
} else {
    Ok "existing git repository detected"
}

# --- commit --------------------------------------------------------------
git add -A
$pending = git status --porcelain
if ($pending) {
    git commit -m "Sanctum: privacy-hardened Firefox fork (overlay, build pipeline, CI)" | Out-Null
    Ok "changes committed"
} else {
    Ok "nothing new to commit"
}

# --- create remote + push ------------------------------------------------
if ($RemoteUrl) {
    if (git remote | Select-String -Quiet '^origin$') { git remote set-url origin $RemoteUrl }
    else { git remote add origin $RemoteUrl }

    git push -u origin main
    if ($LASTEXITCODE -ne 0) {
        if ($Force) {
            Write-Host "  normal push rejected; force-pushing (safe for a brand-new repo)..." -ForegroundColor Yellow
            git push -u origin main --force
            if ($LASTEXITCODE -ne 0) { Fail "force push failed" }
        } else {
            Fail "Push rejected — the remote already has commits (e.g. an auto-created README). Re-run with -Force to overwrite it:  powershell -File push-to-github.ps1 -RemoteUrl $RemoteUrl -Force"
        }
    }
    Ok "pushed to $RemoteUrl"
}
elseif (Get-Command gh -ErrorAction SilentlyContinue) {
    # gh creates the repo, wires 'origin', and pushes in one shot.
    Write-Host "  Creating GitHub repo '$RepoName' ($Visibility) and pushing via gh..." -ForegroundColor Cyan
    gh repo create $RepoName --$Visibility --source . --remote origin --push
    Ok "repository created and pushed: $RepoName"
}
else {
    Write-Host ""
    Write-Host "  No 'gh' CLI and no -RemoteUrl given. Two ways to finish:" -ForegroundColor Yellow
    Write-Host "    A) Install GitHub CLI (https://cli.github.com), run 'gh auth login', then re-run this script."
    Write-Host "    B) Create an EMPTY repo at https://github.com/new (no README), then run:"
    Write-Host "         git remote add origin https://github.com/<you>/$RepoName.git"
    Write-Host "         git push -u origin main"
    exit 2
}

Write-Host ""
Write-Host "Done. Tip: push a tag to trigger the CI build + release:" -ForegroundColor Cyan
Write-Host "    git tag v0.1 ; git push origin v0.1"
