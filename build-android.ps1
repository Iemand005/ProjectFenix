#Requires -Version 5.1
<#
.SYNOPSIS
    Builds the Foxcraft Android native libraries with no machine-specific paths.

.DESCRIPTION
    The CMake presets reference the Android SDK through the ANDROID_SDK_ROOT
    environment variable instead of a hardcoded path. This script resolves that
    variable automatically, in this order:

        1. $env:ANDROID_SDK_ROOT
        2. $env:ANDROID_HOME
        3. Android/Foxcraft/local.properties  (sdk.dir, written by Android Studio)
        4. %LOCALAPPDATA%\Android\Sdk          (default install location)

    It then runs the CMake configure + build presets for the requested ABI(s).
    Nobody has to edit any path to build on their own machine.

.PARAMETER Target
    Which ABI(s) to build. 'both' (default) builds arm64-v8a and armeabi-v7a
    flat, which is exactly what the Gradle 'both' flavor packages into the APK.

.EXAMPLE
    ./build-android.ps1 -Target both
    ./build-android.ps1 -Target arm64
#>
[CmdletBinding()]
param(
    [ValidateSet('both', 'arm64', 'v7a-flat', 'x86_64')]
    [string]$Target = 'both'
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

function Get-AndroidSdk {
    foreach ($candidate in @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME)) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }

    $localProps = Join-Path $repoRoot 'Android/Foxcraft/local.properties'
    if (Test-Path -LiteralPath $localProps) {
        $line = Get-Content -LiteralPath $localProps |
            Where-Object { $_ -match '^\s*sdk\.dir\s*=' } | Select-Object -First 1
        if ($line) {
            # Java .properties escaping: '\\' -> '\', '\:' -> ':', '\=' -> '='.
            $value = ($line -split '=', 2)[1].Trim()
            $value = $value -replace '\\\\', '\' -replace '\\:', ':' -replace '\\=', '='
            if (Test-Path -LiteralPath $value) { return $value }
        }
    }

    if ($env:LOCALAPPDATA) {
        $default = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
        if (Test-Path -LiteralPath $default) { return $default }
    }

    throw ("Could not locate the Android SDK. Set ANDROID_SDK_ROOT, or open the project " +
           "in Android Studio once so it writes Android/Foxcraft/local.properties.")
}

$sdk = Get-AndroidSdk
$ndkVersion = '29.0.14206865'
$cmakeVersion = '3.22.1'

$cmake = Join-Path $sdk "cmake/$cmakeVersion/bin/cmake.exe"
$ndkHome = Join-Path $sdk "ndk/$ndkVersion"

if (-not (Test-Path -LiteralPath $cmake)) {
    throw "CMake $cmakeVersion not found under '$sdk'. Install it via Android Studio's " +
          "SDK Manager (SDK Tools > CMake)."
}
if (-not (Test-Path -LiteralPath $ndkHome)) {
    throw "NDK $ndkVersion not found under '$sdk'. Install it via Android Studio's " +
          "SDK Manager (SDK Tools > NDK (Side by side))."
}

# These are what the CMake presets expand via $env{ANDROID_SDK_ROOT}.
$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_NDK_HOME = $ndkHome
$env:ANDROID_NDK_ROOT = $ndkHome

Write-Host "Android SDK : $sdk"
Write-Host "NDK         : $ndkHome"
Write-Host "CMake       : $cmake"
Write-Host ''

$presets = switch ($Target) {
    'arm64'    { @('android-arm64-debug') }
    'v7a-flat' { @('android-armeabi-v7a-flat') }
    'x86_64'   { @('android-x86_64-debug') }
    'both'     { @('android-arm64-debug', 'android-armeabi-v7a-flat') }
}

foreach ($preset in $presets) {
    Write-Host "==> Configuring $preset" -ForegroundColor Cyan
    & $cmake --preset $preset
    if ($LASTEXITCODE -ne 0) { throw "Configure failed for preset '$preset'." }

    Write-Host "==> Building $preset" -ForegroundColor Cyan
    & $cmake --build --preset $preset
    if ($LASTEXITCODE -ne 0) { throw "Build failed for preset '$preset'." }
}

Write-Host ''
Write-Host "Native libraries built. Package the APK with:" -ForegroundColor Green
Write-Host "  cd Android/Foxcraft; .\gradlew.bat assembleBothDebug"
