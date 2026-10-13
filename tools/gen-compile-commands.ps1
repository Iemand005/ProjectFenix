# Generates compile_commands.json for clangd on native Windows/MSVC.
#
# The Visual Studio CMake generator used for normal builds never emits a
# compilation database, so clangd has nothing current to read. This configures a
# throwaway Ninja build under build/clangd using the real MSVC environment and
# copies the result to the repo root, where .vscode/settings.json points clangd.
#
# Usage:  pwsh -File tools/gen-compile-commands.ps1
# Regenerate after adding/removing source files or changing CMake include paths.

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $repoRoot "build\clangd"

# Locate the Visual Studio installation that ships the MSVC toolset.
$vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
	throw "vswhere.exe not found; install the Visual Studio Build Tools with the C++ workload."
}
$install = & $vswhere -latest -products * `
	-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
	-property installationPath | Select-Object -First 1
if (-not $install) {
	throw "No Visual Studio installation with the C++ toolset was found."
}

$vsDevCmd = Join-Path $install "Common7\Tools\VsDevCmd.bat"
if (-not (Test-Path $vsDevCmd)) {
	throw "VsDevCmd.bat not found under $install."
}

# Prefer the CMake bundled with Visual Studio so the script needs nothing on PATH.
$cmake = Join-Path $install "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
if (-not (Test-Path $cmake)) {
	$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
}
if (-not $cmake -or -not (Test-Path $cmake)) {
	throw "cmake.exe not found (looked in the VS install and on PATH)."
}

# Resolve the Vulkan SDK for the Vulkan backend's shader compilation/headers.
$vulkanSdk = $env:VULKAN_SDK
if (-not $vulkanSdk -or -not (Test-Path $vulkanSdk)) {
	$vulkanSdk = Get-ChildItem "C:\VulkanSDK" -Directory -ErrorAction SilentlyContinue |
		Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
}

$parts = @(
	"call `"$vsDevCmd`" -arch=x64 -host_arch=x64 >nul"
)
if ($vulkanSdk) {
	$parts += "set `"VULKAN_SDK=$vulkanSdk`""
	$parts += "set `"PATH=$vulkanSdk\Bin;%PATH%`""
}
$parts += "`"$cmake`" -G Ninja -S `"$repoRoot`" -B `"$buildDir`" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"

Write-Host "Configuring Ninja build in $buildDir ..."
cmd /c ($parts -join " && ")
if ($LASTEXITCODE -ne 0) {
	throw "CMake configure failed (exit $LASTEXITCODE)."
}

$generated = Join-Path $buildDir "compile_commands.json"
if (-not (Test-Path $generated)) {
	throw "compile_commands.json was not produced at $generated."
}

Copy-Item $generated (Join-Path $repoRoot "compile_commands.json") -Force
Write-Host "Wrote $repoRoot\compile_commands.json"
