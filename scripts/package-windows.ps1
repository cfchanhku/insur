#Requires -Version 5.1
<#
.SYNOPSIS
  Packages an existing Windows release runner directory as a ZIP with SHA-256.
.PARAMETER Version
  Semantic version used in output filenames. Defaults to pubspec.yaml.
.PARAMETER CertificateThumbprint
  Optional signing certificate thumbprint in Cert:\CurrentUser\My.
#>

[CmdletBinding()]
param(
  [string]$Version,
  [string]$CertificateThumbprint
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

if (-not $Version) {
  $versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$'
  if (-not $versionLine) {
    throw 'Cannot read the semantic version from pubspec.yaml.'
  }
  $Version = $versionLine.Matches[0].Groups[1].Value
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  throw 'Version must use MAJOR.MINOR.PATCH format.'
}

$runnerDirectory = Join-Path $repoRoot 'build\windows\x64\runner\Release'
$executable = Join-Path $runnerDirectory 'insur.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
  throw "Release executable not found at $executable. Build Windows first."
}

if ($CertificateThumbprint) {
  $certificate = Get-ChildItem -Path 'Cert:\CurrentUser\My' |
    Where-Object { $_.Thumbprint -eq $CertificateThumbprint } |
    Select-Object -First 1
  if (-not $certificate) {
    throw 'The requested certificate was not found in Cert:\CurrentUser\My.'
  }
  $signTool = Get-Command 'signtool.exe' -ErrorAction SilentlyContinue
  if (-not $signTool) {
    throw 'signtool.exe was not found. Install the Windows SDK or omit signing.'
  }

  & $signTool.Source sign /sha1 $certificate.Thumbprint /s My /fd SHA256 `
    /tr 'https://timestamp.digicert.com' /td SHA256 $executable
  if ($LASTEXITCODE -ne 0) {
    throw "Executable signing failed with exit code $LASTEXITCODE."
  }
  & $signTool.Source verify /pa /v $executable
  if ($LASTEXITCODE -ne 0) {
    throw "Executable signature verification failed with exit code $LASTEXITCODE."
  }
} else {
  Write-Warning 'Packaging unsigned. Windows may show a SmartScreen warning.'
}

$outputDirectory = Join-Path $repoRoot 'build\release'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$zipPath = Join-Path $outputDirectory "InsurancePolicyManager_v${Version}_windows.zip"
$hashPath = "$zipPath.sha256"

Compress-Archive -Path (Join-Path $runnerDirectory '*') `
  -DestinationPath $zipPath -CompressionLevel Optimal -Force
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
  throw 'ZIP package was not created.'
}

$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $hashPath -Value "$hash  $(Split-Path -Leaf $zipPath)" `
  -Encoding Ascii -NoNewline

Write-Host "Package: $zipPath"
Write-Host "SHA-256: $hash"
