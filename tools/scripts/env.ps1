# Common environment for GDExtension build scripts on Windows (PowerShell 7+).
# Dot-source from each build-*.ps1: `. "$PSScriptRoot/env.ps1"`
#
# Each variable falls back to a default only when not already set in the
# session. Override on the command line as needed:
#   $env:WWISE_SDK = 'C:\other\path'; .\tools\scripts\build-windows.ps1

# Project root (resolved from this file's location).
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = (Resolve-Path "$PSScriptRoot/../..").Path
}

# Wwise SDK — Wwise Launcher sets %WWISESDK% automatically; honor it if present.
if (-not $env:WWISE_SDK) {
    if ($env:WWISESDK) {
        $env:WWISE_SDK = $env:WWISESDK
    } else {
        $env:WWISE_SDK = 'C:\Audiokinetic\Wwise_2025.1.3.9039\SDK'
    }
}

# Python venv SCons (Windows layout).
if (-not $env:SCONS) {
    $env:SCONS = Join-Path $env:PROJECT_ROOT '.venv\Scripts\scons.exe'
}

# Build parallelism.
if (-not $env:JOBS) {
    $env:JOBS = "$([Environment]::ProcessorCount)"
}

# MSVC + Python encoding fixes for Japanese / non-English locales.
# PYTHONIOENCODING=utf-8 is the actual fix; VSLANG=1033 is best-effort.
if (-not $env:PYTHONIOENCODING) { $env:PYTHONIOENCODING = 'utf-8' }
if (-not $env:VSLANG)           { $env:VSLANG           = '1033' }

# Sanity check that doesn't abort dot-sourcing (callers decide what's required).
# Guard against an empty $env:SCONS so Test-Path doesn't throw under StrictMode.
if ($env:SCONS -and -not (Test-Path $env:SCONS)) {
    Write-Warning "SCons not found at $env:SCONS — run docs/host-setup-windows.md steps first"
}
