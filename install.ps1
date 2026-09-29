<#
.SYNOPSIS
    Install the technext-sales-proposal skill into an agent's skills directory.

.DESCRIPTION
    Creates <Destination>/technext-sales-proposal holding only the skill itself (SKILL.md,
    plus links to assets/ and agents/), and links each of
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

.PARAMETER Force
    Overwrite agent files in <host>/agents that differ from this repository's copy.

.PARAMETER DryRun
    Show what would happen without touching anything.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1 -Destination "$HOME\.codex\skills" -Copy
#>
[CmdletBinding()]
param(
    [string]$Destination,
    [switch]$Copy,
    [switch]$SkipSubSkills,
    [switch]$Force,
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

$Marker = '.installed-by-technext-sales-proposal'

function Install-Orchestrator {
    # A clean skill folder: SKILL.md + assets/ + agents/ only, never the whole repository
    # (install scripts, reports, the second copy of the sub-skills under skills/).
    param([string]$SkillPath)
    if (Test-Path -LiteralPath $SkillPath) {
        if (Test-IsLink -Path $SkillPath) {
            # older installs linked the whole repository here
            if ($DryRun) { Write-Host "  [dry-run] would replace old repo link $SkillPath" -ForegroundColor DarkGray }
            else { Remove-Link -Path $SkillPath }
        }
        elseif (-not (Test-Path -LiteralPath (Join-Path $SkillPath $Marker))) {
            Write-Warning "  skipped (a real folder already exists): $SkillPath"
            return
        }
    }
    if ($DryRun) { Write-Host "  [dry-run] $SkillPath <- SKILL.md, assets/, agents/" -ForegroundColor DarkGray; return }
    New-Item -ItemType Directory -Path $SkillPath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $SkillPath $Marker) -Value $RepoRoot -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'SKILL.md') -Destination (Join-Path $SkillPath 'SKILL.md') -Force
    foreach ($d in 'assets', 'agents') {
        Install-Link -LinkPath (Join-Path $SkillPath $d) -TargetPath (Join-Path $RepoRoot $d)
    }
    Write-Host "  ready   $SkillPath (SKILL.md is a copy: re-run this installer after git pull)"
}

function Install-AgentFile {
    # Files can't be junctions, and symlinks need admin/Developer Mode on Windows - copy.
    param([string]$Dest, [string]$Src)
    if (Test-Path -LiteralPath $Dest) {
        $same = (Get-FileHash -LiteralPath $Dest).Hash -eq (Get-FileHash -LiteralPath $Src).Hash
        if ($same) { Write-Host "  up to date $Dest"; return }
        if (-not $Force) {
            Write-Warning "  skipped (differs from this repo; re-run with -Force to overwrite): $Dest"
            return
        }
    }
    if ($DryRun) { Write-Host "  [dry-run] copy $Src -> $Dest" -ForegroundColor DarkGray; return }
    Copy-Item -LiteralPath $Src -Destination $Dest -Force
    Write-Host "  copied  $Dest"
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
Install-Orchestrator -SkillPath (Join-Path $Destination $SkillName)

if (-not $SkipSubSkills) {
    Write-Host "`nSub-skills"
    Get-ChildItem -LiteralPath $SubDir -Directory | Sort-Object Name | ForEach-Object {
        Install-Link -LinkPath (Join-Path $Destination $_.Name) -TargetPath $_.FullName
    }
}

# Claude Code discovers subagents in <host>/agents, next to <host>/skills - the pipeline
# dispatches the 5 research agents by name, so they must be installed there too.
$AgentSrc = Join-Path $RepoRoot 'agents'
$HostDir  = Split-Path -Parent $Destination
if ((Test-Path -LiteralPath $AgentSrc) -and ((Split-Path -Leaf $HostDir) -eq '.claude')) {
    $AgentDest = Join-Path $HostDir 'agents'
    Write-Host "`nSubagents -> $AgentDest"
    if (-not (Test-Path -LiteralPath $AgentDest)) {
        if ($DryRun) { Write-Host "  [dry-run] would create $AgentDest" -ForegroundColor DarkGray }
        else { New-Item -ItemType Directory -Path $AgentDest -Force | Out-Null }
    }
    Get-ChildItem -LiteralPath $AgentSrc -Filter '*.md' | Sort-Object Name | ForEach-Object {
        Install-AgentFile -Dest (Join-Path $AgentDest $_.Name) -Src $_.FullName
    }
}
elseif (Test-Path -LiteralPath $AgentSrc) {
    Write-Host "`nSubagents: not a Claude Code skills dir - install the 5 files in agents/ with your agent's own sub-agent mechanism (see README)." -ForegroundColor Yellow
}

Write-Host "`nDone. Restart your agent, then ask it for a sales proposal to test the install."
