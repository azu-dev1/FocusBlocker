$javaDir = "C:\Java"
$javaHome = "$javaDir\jdk-17"
$tempZip = "$env:TEMP\java17.zip"

Write-Host "Installing Java 17..." -ForegroundColor Cyan

if (-not (Test-Path $javaDir)) {
    New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
}

$url = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10+7/OpenJDK17U-jdk_x64_windows_hotspot_17.0.10_7.zip"

Write-Host "Downloading Java 17..." -ForegroundColor Yellow

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($url, $tempZip)

Write-Host "Download complete - extracting..." -ForegroundColor Green

Expand-Archive -Path $tempZip -DestinationPath $javaDir -Force

$extracted = Get-ChildItem $javaDir -Directory | Where-Object {$_.Name -match "jdk"} | Select-Object -First 1
if ($extracted -and $extracted.Name -ne "jdk-17") {
    Rename-Item -Path $extracted.FullName -NewName "jdk-17" -Force
}

Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;$env:PATH"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "User")

Write-Host "Java 17 installed at: $javaHome" -ForegroundColor Green

& "$javaHome\bin\java.exe" -version

Write-Host "Java 17 setup complete!" -ForegroundColor Green
