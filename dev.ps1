# Starts the two long-running processes used for local development:
#   1. darklua in watch mode, which rebuilds dist/Phasma.luau on every save
#   2. rojo serve, which syncs the selected project to Studio
#
# Usage:
#   powershell -File dev.ps1
#   powershell -File dev.ps1 -Project dev.project.json
#
# The second form serves the private test harness, which is not distributed
# with this repository. Ctrl+C stops Rojo; the darklua window stays open until
# it is closed.

param(
	[string]$Project = "default.project.json"
)

$root = $PSScriptRoot
$darklua = Join-Path $root "tools\darklua.exe"
$rojo = Join-Path $root "tools\rojo.exe"
$projectPath = Join-Path $root $Project

if (-not (Test-Path $darklua) -or -not (Test-Path $rojo)) {
	Write-Error "tools\ is missing darklua.exe or rojo.exe. Copy the binaries into tools\ first."
	exit 1
}

if (-not (Test-Path (Join-Path $root "dist"))) {
	New-Item -ItemType Directory -Path (Join-Path $root "dist") | Out-Null
}

if (-not (Test-Path $projectPath)) {
	Write-Error "Project not found: $Project"
	exit 1
}

Start-Process -FilePath $darklua `
	-ArgumentList @("process", "src/Init.luau", "dist/Phasma.luau", "-c", "build/darklua.json", "-w") `
	-WorkingDirectory $root

& $rojo serve $projectPath
