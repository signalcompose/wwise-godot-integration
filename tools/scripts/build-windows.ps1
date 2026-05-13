# Build Windows editor + template_debug + template_release (x64).
# Intended to run on a Windows host with Visual Studio 2022 (MSVC) installed.
# Run from any directory; the script resolves its own paths.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. "$PSScriptRoot/env.ps1"

# Sanity: refuse to run on non-Windows hosts to avoid silently producing wrong-target artifacts.
if (-not $IsWindows) {
    Write-Error "build-windows.ps1 must run on a Windows host. SConstruct uses MSVC-only flags and cannot cross-compile from macOS/Linux."
    exit 1
}

Push-Location (Join-Path $env:PROJECT_ROOT 'addons/Wwise/native')
try {
    function Invoke-SCons {
        # $BuildProfile (not $Profile) to avoid shadowing PowerShell's
        # automatic $Profile variable (path to user's profile script).
        param(
            [string]$Target,
            [string]$Config,
            [string]$BuildProfile
        )
        Write-Host ":: windows $Target ($Config, $BuildProfile) ::"
        # Quote the full key=value token so paths containing spaces survive
        # PowerShell's native-command argument parsing (older pwsh < 7.3).
        & $env:SCONS `
            platform=windows `
            target=$Target `
            wwise_config=$Config `
            use_static_cpp=yes `
            "wwise_sdk=$env:WWISE_SDK" `
            build_profile=$BuildProfile `
            precision=single `
            "-j$env:JOBS"
        if ($LASTEXITCODE -ne 0) {
            throw "scons failed for windows $Target ($Config) with exit code $LASTEXITCODE"
        }
    }

    Invoke-SCons -Target 'editor'           -Config 'profile' -BuildProfile 'build_profile_editor.json'
    Invoke-SCons -Target 'template_debug'   -Config 'profile' -BuildProfile 'build_profile_runtime.json'
    Invoke-SCons -Target 'template_release' -Config 'release' -BuildProfile 'build_profile_runtime.json'

    Write-Host "Windows build complete."
} finally {
    Pop-Location
}
