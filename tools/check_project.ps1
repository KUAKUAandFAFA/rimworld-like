[CmdletBinding()]
param(
	[string]$GodotExe = "D:\codes\Godot\Godot_v4.6.1-stable_win64.exe",
	[switch]$SkipGitDiffCheck
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $PSCommandPath
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")

function Write-Step {
	param([string]$Message)

	Write-Host ""
	Write-Host "==> $Message"
}

function Fail-Check {
	param([string]$Message)

	Write-Error $Message
	exit 1
}

function Assert-PathExists {
	param([string]$RelativePath)

	$path = Join-Path $projectRoot $RelativePath
	if (-not (Test-Path -LiteralPath $path)) {
		Fail-Check "Missing required path: $RelativePath"
	}
}

function Assert-ResourceId {
	param(
		[string]$RelativePath,
		[string]$ExpectedId
	)

	$path = Join-Path $projectRoot $RelativePath
	Assert-PathExists $RelativePath

	$content = Get-Content -Raw -LiteralPath $path
	if ($content -notmatch "(?m)^id = `"$([regex]::Escape($ExpectedId))`"$") {
		Fail-Check "Resource $RelativePath does not define id `"$ExpectedId`"."
	}
}

Write-Step "Checking required project files"
Assert-PathExists "project.godot"
Assert-PathExists "scenes\main.tscn"
Assert-PathExists "scripts\app\game_root.gd"
Assert-PathExists "scripts\data\definition_registry.gd"

Write-Step "Checking required definition resources"
Assert-ResourceId "resources\items\food.tres" "food"
Assert-ResourceId "resources\items\wood.tres" "wood"
Assert-ResourceId "resources\terrain\grass.tres" "grass"
Assert-ResourceId "resources\terrain\soil.tres" "soil"
Assert-ResourceId "resources\terrain\stone.tres" "stone"
Assert-ResourceId "resources\terrain\water.tres" "water"
Assert-ResourceId "resources\jobs\harvest.tres" "harvest"

Write-Step "Running Godot headless project load"
if (-not (Test-Path -LiteralPath $GodotExe)) {
	Fail-Check "Godot executable not found: $GodotExe"
}

& $GodotExe --headless --path $projectRoot --quit
$godotExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
if ($godotExitCode -ne 0) {
	Fail-Check "Godot headless project load failed with exit code $godotExitCode."
}

if (-not $SkipGitDiffCheck) {
	Write-Step "Running git diff --check"
	git -C $projectRoot diff --check
	$gitDiffExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
	if ($gitDiffExitCode -ne 0) {
		Fail-Check "git diff --check failed with exit code $gitDiffExitCode."
	}
}

Write-Host ""
Write-Host "All automated parse and smoke checks passed."
