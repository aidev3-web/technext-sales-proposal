<#
.SYNOPSIS
    Install the technext-sales-proposal skill into an agent's skills directory.

.DESCRIPTION
    Links <Destination>/technext-sales-proposal to this repository, and links each of
    the 12 sub-skills (incl. diagram-design, social-browser-scan) under skills/ into <Destination>/<name> - the pipeline dispatches
    those sub-skills by name, so they must be discoverable on their own.

    An existing real folder is never overwritten; it is reported and skipped. Existing
    links pointing at this repository are refreshed. Use -Copy where symlinks or
    junctions are not available.

.PARAMETER Destination
    The agent skills directory to install into. If omitted, every known skills
    directory that exists is listed and you are asked to pick one with -Destination.

.PARAMETER Copy
    Copy the files instead of creating links.

.PARAMETER SkipSubSkills
    Install only the orchestrator skill, not the 12 sub-skills (incl. diagram-design, social-browser-scan).

.PARAMETER DryRun
    Show what would happen without touching anything.

.EXAMPLE
    pwsh -File install.ps1

.EXAMPLE
    pwsh -File install.ps1 -Destination "$HOME\.codex\skills" -Copy
#>
[CmdletBinding()]
param(
    [string]$Destination,
    [switch]$Copy,
    [switch]$SkipSubSkills,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$SkillName = 'technext-sales-proposal'
$RepoRoot  = $PSScriptRoot
$SubDir    = Join-Path $RepoRoot 'skills'

function Get-CandidateDirs {
    $names = @(
        (Join-Path $HOME '.claude\skills'),
        (Join-Path $HOME '.codex\skills'),
        (Join-Path $HOME '.config\opencode\skills'),
        (Join-Path $HOME '.gemini\skills'),
        (Join-Path $HOME '.copilot\skills'),
        (Join-Path $HOME '.cursor\skills')
    )
    $names | Where-Object { Test-Path -LiteralPath $_ }
}

function Test-IsLink {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return $false }
    return [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
}

function Remove-Link {
    param([string]$Path)
    # Removes the link itself, never the directory it points at.
    [System.IO.Directory]::Delete($Path, $false)
}

function Install-Link {
    param([string]$LinkPath, [string]$TargetPath)
    if (Test-Path -LiteralPath $LinkPath) {
        if (Test-IsLink -Path $LinkPath) {
            if ($DryRun) { Write-Host "  [dry-run] would refresh $LinkPath" -ForegroundColor DarkGray; return }
            Remove-Link -Path $LinkPath
        }
        else {
            Write-Warning "  skipped (a real folder already exists): $LinkPath"
            return
        }
    }
    if ($DryRun) {
        Write-Host "  [dry-run] $LinkPath -> $TargetPath" -ForegroundColor DarkGray
        return
    }
    if ($Copy) {
        Copy-Item -LiteralPath $TargetPath -Destination $LinkPath -Recurse -Force
        Write-Host "  copied  $LinkPath"
        return
    }
    try {
        New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -ErrorAction Stop | Out-Null
        Write-Host "  linked  $LinkPath"
    }
    catch {
        Write-Warning "  junction failed ($($_.Exception.Message)); copying instead"
        Copy-Item -LiteralPath $TargetPath -Destination $LinkPath -Recurse -Force
        Write-Host "  copied  $LinkPath"
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot 'SKILL.md'))) {
    throw "SKILL.md not found next to this script - run the installer from the repository root."
}

if (-not $Destination) {
    $candidates = Get-CandidateDirs
    if ($candidates.Count -eq 1) {
        $Destination = $candidates[0]
        Write-Host "Using the only agent skills directory found: $Destination`n"
    }
    elseif ($candidates.Count -eq 0) {
        throw "No agent skills directory found. Re-run with -Destination <path to your agent's skills dir>."
    }
    else {
        Write-Host "Several agent skills directories exist. Re-run with -Destination <path>:`n"
        $candidates | ForEach-Object { Write-Host "  -Destination `"$_`"" }
        exit 1
    }
}

$Destination = [System.IO.Path]::GetFullPath($Destination)

Write-Host "Source      : $RepoRoot"
Write-Host "Destination : $Destination"
Write-Host "Mode        : $(if ($Copy) { 'copy' } else { 'link' })$(if ($DryRun) { ' (dry run)' } else { '' })"
Write-Host ""

if (-not (Test-Path -LiteralPath $Destination)) {
    if ($DryRun) { Write-Host "  [dry-run] would create $Destination" -ForegroundColor DarkGray }
    else { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }
}

Write-Host "Orchestrator skill"
Install-Link -LinkPath (Join-Path $Destination $SkillName) -TargetPath $RepoRoot

if (-not $SkipSubSkills) {
    Write-Host "`nSub-skills"
    Get-ChildItem -LiteralPath $SubDir -Directory | Sort-Object Name | ForEach-Object {
        Install-Link -LinkPath (Join-Path $Destination $_.Name) -TargetPath $_.FullName
    }
}

Write-Host "`nDone. Ask your agent for a sales proposal to test the install."
