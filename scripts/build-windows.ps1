#Requires -Version 5.1
<#
.SYNOPSIS
  Builds and packages the Windows release using the repository's FVM pin.
.PARAMETER Version
  Optional product version override for the package filename.
.PARAMETER CertificateThumbprint
  Optional thumbprint of a signing certificate in the current user's
  Personal certificate store. Only the application executable is signed.
#>

[CmdletBinding()]
param(
  [string]$Version,
  [string]$CertificateThumbprint
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

if (-not (Get-Command 'fvm' -ErrorAction SilentlyContinue)) {
  throw 'FVM was not found. Install FVM and run fvm install from the repository root.'
}

$versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$'
if (-not $Version) {
  if (-not $versionLine) {
    throw 'Cannot read the semantic version from pubspec.yaml.'
  }
  $Version = $versionLine.Matches[0].Groups[1].Value
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  throw 'Version must use MAJOR.MINOR.PATCH format.'
}

Write-Host "Building Insurance Policy Manager v$Version for Windows..."
& fvm flutter build windows --release
if ($LASTEXITCODE -ne 0) {
  throw "Flutter Windows build failed with exit code $LASTEXITCODE."
}

$packageArgs = @{
  Version = $Version
}
if ($CertificateThumbprint) {
  $packageArgs.CertificateThumbprint = $CertificateThumbprint
}
& (Join-Path $PSScriptRoot 'package-windows.ps1') @packageArgs
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
  throw "Windows packaging failed with exit code $LASTEXITCODE."
}
