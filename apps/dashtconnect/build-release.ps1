# Build APK release siap pasang. Jalankan dari folder mana saja:
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
