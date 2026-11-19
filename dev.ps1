# Starts the two long-running processes the test place needs:
#   1. darklua in watch mode, which rebuilds dist/Phasma.luau on every save
#   2. rojo serve, which syncs the place tree (including the dev panel) live
#
# Run from any directory:  powershell -File dev.ps1
# Ctrl+C stops Rojo; the darklua window stays open until closed.

$root = $PSScriptRoot
$darklua = Join-Path $root "tools\darklua.exe"
$rojo = Join-Path $root "tools\rojo.exe"

if (-not (Test-Path $darklua) -or -not (Test-Path $rojo)) {
	Write-Error "tools\ is missing darklua.exe or rojo.exe. Copy the binaries into tools\ first."
	exit 1
}

if (-not (Test-Path (Join-Path $root "dist"))) {
	New-Item -ItemType Directory -Path (Join-Path $root "dist") | Out-Null
}

Start-Process -FilePath $darklua `
	-ArgumentList @("process", "src/Init.luau", "dist/Phasma.luau", "-c", "build/darklua.json", "-w") `
	-WorkingDirectory $root

& $rojo serve (Join-Path $root "default.project.json")
