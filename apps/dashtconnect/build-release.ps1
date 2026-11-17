# Build APK release lalu pasang ke HP yang tersambung. Jalankan dari folder mana saja:
#   powershell -ExecutionPolicy Bypass -File apps\dashtconnect\build-release.ps1
# Butuh android/key.properties dan dashtconnect.authAssetsDir di android/local.properties.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# Temp pendek menghindari error Java "Unable to establish loopback connection".
$buildTemp = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\.local-tools\java-tmp'))
New-Item -ItemType Directory -Path $buildTemp -Force | Out-Null
$env:TEMP = $buildTemp
$env:TMP = $buildTemp

flutter build apk --release --target-platform android-arm64
if ($LASTEXITCODE -ne 0) { throw "Build gagal (exit $LASTEXITCODE)." }

$version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value -replace '\+', '-b'
$out = Join-Path $PSScriptRoot "build\dashtconnect-$version.apk"
Copy-Item build\app\outputs\flutter-apk\app-release.apk $out -Force
Write-Host "`nAPK siap: $out"

# Pasang ke HP yang tersambung lewat USB (USB debugging aktif), lalu buka aplikasinya.
$sdkDir = (Select-String -Path android\local.properties -Pattern '^sdk\.dir=(.+)').Matches[0].Groups[1].Value -replace '\\\\', '\' -replace '\\:', ':'
$adb = Join-Path $sdkDir 'platform-tools\adb.exe'
$devices = & $adb devices | Select-String '\tdevice$'
if (-not $devices) { Write-Host 'Tidak ada HP tersambung; APK tidak dipasang.'; exit 0 }
& $adb install -r $out
if ($LASTEXITCODE -ne 0) { throw "Install gagal (exit $LASTEXITCODE)." }
& $adb shell 'monkey -p io.github.farhanreninda.dashtconnect -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1'
Write-Host 'Aplikasi terpasang dan dibuka di HP.'
