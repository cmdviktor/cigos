# Builds the portable Windows package: dist\Sung\sung.exe + Qt + Python runtime + ffmpeg.
# Needs: Qt 6.8+ (MinGW kit) on PATH together with its MinGW compiler, CMake, Ninja.
# Usage:  powershell -ExecutionPolicy Bypass -File scripts\package-windows.ps1
param(
  [string]$BuildDir = "build-win",
  [string]$Dist = "dist\Sung",
  [string]$PythonVersion = "3.12.8"
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

function Download($url, $out) {
  Write-Host "Downloading $url"
  Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
}

# 1. Configure, build, install -------------------------------------------------
cmake -S . -B $BuildDir -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
if ($LASTEXITCODE) { throw "cmake configure failed" }
cmake --build $BuildDir
if ($LASTEXITCODE) { throw "build failed" }
if (Test-Path $Dist) { Remove-Item -Recurse -Force $Dist }
cmake --install $BuildDir --prefix $Dist
if ($LASTEXITCODE) { throw "install failed" }

# 2. Qt runtime (DLLs, plugins, multimedia backend) ---------------------------------
windeployqt --release --no-translations --qmldir qml "$Dist\sung.exe"
if ($LASTEXITCODE) { throw "windeployqt failed" }
# The FFmpeg libraries Qt Multimedia loads are not always picked up by the scan.
$qtBin = Split-Path (Get-Command windeployqt).Source
Get-ChildItem $qtBin -Filter "av*.dll" -ErrorAction SilentlyContinue | Copy-Item -Destination $Dist -Force
Get-ChildItem $qtBin -Filter "sw*.dll" -ErrorAction SilentlyContinue | Copy-Item -Destination $Dist -Force

# 3. Python runtime for the helper (YouTube Music, local library scan) -----------------
$tmp = Join-Path $BuildDir "downloads"
New-Item -ItemType Directory -Force $tmp | Out-Null
$runtime = Join-Path $Dist "runtime"
$pyZip = Join-Path $tmp "python-embed.zip"
Download "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-embed-amd64.zip" $pyZip
Expand-Archive $pyZip -DestinationPath $runtime -Force
$pth = Get-ChildItem $runtime -Filter "python*._pth" | Select-Object -First 1
$lines = Get-Content $pth.FullName | ForEach-Object { if ($_ -match '^#\s*import site') { 'import site' } else { $_ } }
$lines += "Lib\site-packages"
$lines += "..\helper"
Set-Content -Path $pth.FullName -Value $lines -Encoding ASCII
$getPip = Join-Path $tmp "get-pip.py"
Download "https://bootstrap.pypa.io/get-pip.py" $getPip
& "$runtime\python.exe" $getPip --no-warn-script-location
if ($LASTEXITCODE) { throw "pip bootstrap failed" }
& "$runtime\python.exe" -m pip install --no-warn-script-location -r "$Dist\helper\requirements.txt"
if ($LASTEXITCODE) { throw "helper requirements failed" }

# 4. ffmpeg / ffprobe (local library scan, artwork) --------------------------------------
$ffZip = Join-Path $tmp "ffmpeg.zip"
Download "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip" $ffZip
$ffTmp = Join-Path $tmp "ffmpeg"
Expand-Archive $ffZip -DestinationPath $ffTmp -Force
New-Item -ItemType Directory -Force "$Dist\ffmpeg" | Out-Null
Get-ChildItem $ffTmp -Recurse -Include ffmpeg.exe, ffprobe.exe | Copy-Item -Destination "$Dist\ffmpeg" -Force

# 5. Smoke test + zip ---------------------------------------------------------------------
& "$Dist\sung.exe" --version
Compress-Archive -Path $Dist -DestinationPath "dist\Sung-Windows.zip" -Force
Write-Host "Done: dist\Sung\sung.exe and dist\Sung-Windows.zip"
