# Development Setup Guide

This guide provisions the Insurance Policy Manager (`insur`) development toolchain. The application is a local-only Flutter/Dart project for sensitive insurance information. GitHub is for source code only; never use real user data, secrets, or production backups during development.

## Table of contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Windows 11 Setup](#3-windows-11-setup)
4. [macOS Setup](#4-macos-setup)
5. [Repository Setup](#5-repository-setup)
6. [FVM](#6-fvm)
7. [IDE Configuration](#7-ide-configuration)
8. [Running the App](#8-running-the-app)
9. [Building for Release](#9-building-for-release)
10. [Symbols Management](#10-symbols-management)
11. [Troubleshooting](#11-troubleshooting)
12. [Quick Reference](#12-quick-reference)
13. [No Python virtual environment needed](#13-no-python-virtual-environment-needed)

## 1. Overview

The supported development arrangement is a two-machine setup: Windows 11 is the primary coding environment and required for Windows builds; macOS is required for iOS and macOS builds. GitHub stores code and review history only.

| Work | Windows 11 | macOS | GitHub |
|---|---|---|---|
| Primary feature development | Yes | Supported | No |
| Windows desktop build | Required | No | No |
| iOS/macOS build and signing | No | Required | No |
| Android build | Optional | Optional | No |
| Source sync/review | SSH Git client | SSH Git client | Canonical remote |
| Application data and secrets | Never transfer real data | Never transfer real data | Prohibited |

### Prerequisites summary

| Requirement | Windows 11 | macOS |
|---|---|---|
| Flutter/Dart | FVM-pinned Flutter | FVM-pinned Flutter |
| Native desktop toolchain | Visual Studio 2022, Desktop C++ | Xcode 26 |
| iOS tooling | — | Xcode 26, CocoaPods |
| Version control | Git + SSH | Git + SSH |
| Editor | VS Code + Flutter/Dart extensions | VS Code + Flutter/Dart extensions |
| Secret handling | Windows credential protection | macOS Keychain |

## 2. Prerequisites

### Hardware

- Windows 11 64-bit workstation with available disk space for Flutter, Visual Studio, SDKs, and build artifacts.
- A supported macOS computer with enough storage for Xcode, simulators, Flutter, and archives.
- Optional Android device/emulator and Android SDK for Android development.
- Optional iPhone/iPad for physical-device testing; simulator validation does not replace device testing.
- Encrypted local storage and a trusted backup process for source and development configuration. Do not include app user data or signing secrets in source backups.

### Accounts and network

- GitHub account with least-privilege access to the private repository.
- Apple Developer account for signing and distribution (release personnel only).
- Network access to official SDK/package repositories for installation. App runtime must not depend on network services.
- Organization-approved private security-reporting contact and secrets-management process.

### Data-handling prerequisites

Use only synthetic records. Never use customer data in development, screenshots, crash reports, pull requests, issue trackers, or test databases. Do not configure a development service that uploads logs or application data.

## 3. Windows 11 Setup

### Git

Install the current Git for Windows release from the official source. Enable OpenSSH or use the bundled OpenSSH client. Confirm:

```powershell
git --version
ssh -V
```

### Flutter SDK and FVM

Install FVM using the organization-approved method, then install the Flutter SDK selected by the repository's `.fvmrc` after cloning. Do not use a global `flutter` command for project work. See [FVM](#6-fvm).

### Visual Studio 2022

Install Visual Studio 2022 with the **Desktop development with C++** workload, including the MSVC toolchain, CMake tools, and a Windows SDK. This is required for Windows desktop builds. Verify with `fvm flutter doctor -v`.

### VS Code and extensions

Install VS Code and the official Dart and Flutter extensions. Configure the workspace to use FVM's SDK path where needed; avoid committing machine-specific absolute paths.

### OpenSSL for SQLCipher

Only install OpenSSL if the selected SQLCipher package/native build requires a separately provisioned OpenSSL dependency. Confirm the required version, architecture, license, and source with the implementation owner. Use an official or organization-approved distribution; do not download arbitrary DLLs. Keep native libraries and certificates out of application data and source-control secrets.

### SSH for GitHub

Create a user-specific SSH key using an approved modern key type and protect it with a passphrase. Add only the public key to the GitHub account. Keep the private key in the Windows user's protected SSH/credential store; never copy it into the repository or to another machine.

```powershell
ssh -T git@github.com
```

Verify the host fingerprint against GitHub's current official documentation before first connection.

### Git configuration

Set an identity consistent with the GitHub account, and enable safe line endings:

```powershell
git config --global user.name "Your Name"
git config --global user.email "your-address@example.com"
git config --global core.autocrlf true
git config --global init.defaultBranch main
```

Do not put access tokens, private keys, or credentials in Git configuration.

## 4. macOS Setup

### Xcode 26

Install Xcode 26 from Apple's official distribution, open it once to complete setup, accept the license, and install command-line tools. Select the intended Xcode installation with `xcode-select` only if multiple versions exist. Install required simulator runtimes from Xcode settings.

```bash
xcodebuild -version
xcode-select -p
```

### Homebrew

Homebrew is optional. If used, install it from its official source and use it for developer tooling such as FVM or Git only according to the team's supported setup. Do not use unreviewed tap formulas for cryptographic or signing dependencies.

### Flutter, CocoaPods, and VS Code

Install FVM and use the repository pin. Install CocoaPods using an organization-approved method compatible with the project; run `pod --version`. Install VS Code plus the official Dart and Flutter extensions.

### SSH for GitHub and Git configuration

Create a separate user SSH key on this Mac, protect it with a passphrase, add only the public key to GitHub, and store the private key in macOS Keychain/SSH agent. Do not copy the Windows private key.

```bash
ssh -T git@github.com
git config --global user.name "Your Name"
git config --global user.email "your-address@example.com"
git config --global core.autocrlf input
git config --global init.defaultBranch main
```

### Apple Developer signing

Only authorized release personnel should access distribution signing. Use the organization's Apple account and approved certificate/provisioning profile workflow. Keep signing identities in Keychain or an approved secret manager, use least privilege, and never commit certificates, private keys, provisioning profiles, or credentials.

## 5. Repository Setup

Clone the private source repository independently on each workstation, using SSH:

```shell
git clone git@github.com:<owner>/<repository>.git
cd <repository>
fvm install
fvm flutter pub get
fvm flutter doctor -v
fvm flutter analyze
fvm flutter test
```

Some commands will only succeed once the corresponding Flutter scaffold, dependencies, or tests exist. Record and resolve missing platform prerequisites; do not create fake success results. Verify the `fvm flutter --version` output matches `.fvmrc`. Use synthetic data only.

When changing machines, push/pull source commits through Git. Do not copy working databases, exports, signing files, `.env`, `secrets/`, or user data between machines.

## 6. FVM

FVM pins and selects the Flutter SDK per repository to reduce version drift across the Windows/macOS workstations and CI. The root `.fvmrc` is the version source of truth.

```shell
fvm install
fvm flutter --version
fvm flutter doctor -v
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm dart format .
```

Do not change `.fvmrc` casually. Flutter SDK upgrades require compatibility review, CI/build validation on supported machines, and a documented change. IDEs should use the repository-local FVM SDK; avoid committing absolute paths that only exist on one developer's machine.

## 7. IDE Configuration

Use project-relative configuration. Merge these examples with existing workspace settings; do not overwrite project-specific settings. The `.vscode` directory may be selectively tracked for shared, non-secret configuration.

### `.vscode/settings.json`

```json
{
  "dart.flutterSdkPath": ".fvm\\flutter_sdk",
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true
  }
}
```

On macOS, use the FVM symlink path format expected by the installed FVM version and Dart extension; validate it in VS Code rather than committing an absolute user path.

### `.vscode/launch.json`

Flutter's `deviceId` values can vary by machine. Select a device in VS Code or replace the placeholder with the output from `fvm flutter devices`.

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "insur (Windows)",
      "request": "launch",
      "type": "dart",
      "deviceId": "windows"
    },
    {
      "name": "insur (macOS)",
      "request": "launch",
      "type": "dart",
      "deviceId": "macos"
    },
    {
      "name": "insur (iOS Simulator)",
      "request": "launch",
      "type": "dart",
      "deviceId": "ios"
    },
    {
      "name": "insur (Android)",
      "request": "launch",
      "type": "dart",
      "deviceId": "android"
    },
    {
      "name": "insur (Linux)",
      "request": "launch",
      "type": "dart",
      "deviceId": "linux"
    }
  ]
}
```

Configure platform targets in Flutter and install the required SDKs first. Do not add `env` entries containing secrets or real user data.

## 8. Running the App

List available targets:

```shell
fvm flutter devices
```

Launch using an explicit device:

```powershell
# Windows 11
fvm flutter run -d windows
```

```bash
# iOS Simulator, macOS desktop, or Android (device id may differ)
fvm flutter run -d ios
fvm flutter run -d macos
fvm flutter run -d android
```

Run Linux desktop only on a configured Linux host:

```shell
fvm flutter run -d linux
```

Flutter's hot reload is available during supported debug sessions (press `r` in the terminal). Hot reload does not rerun application initialization; use hot restart for initialization changes. Neither operation is a substitute for a clean test or release build.

## 9. Building for Release

Run tests and analysis before compiling. Release builds must be made on the target-supported machine and use approved signing assets stored outside the repository. Commands may require project-specific flavor and signing configuration.

### Windows

```powershell
fvm flutter build windows --release --obfuscate --split-debug-info=.\symbols\windows\<version>
```

Package and sign the resulting runner using the approved Windows packaging/signing process. Do not assume Flutter produces a finalized installer.

### macOS

```bash
fvm flutter build macos --release --obfuscate --split-debug-info=./symbols/macos/<version>
```

Sign with the approved Developer ID identity, package, notarize, and staple according to current Apple requirements. Verify the final distributed package on a clean supported Mac.

### iOS

```bash
fvm flutter build ipa --release --obfuscate --split-debug-info=./symbols/ios/<version>
```

Configure signing through Xcode/approved CI secret handling, validate entitlements and privacy declarations, upload the archive to App Store Connect, complete review metadata, TestFlight testing, and submit for App Review. Do not commit provisioning profiles or certificates.

### Android

```shell
fvm flutter build appbundle --release --obfuscate --split-debug-info=./symbols/android/<version>
```

Use the approved Android signing configuration and protected keystore/password handling. Validate the signed AAB in an internal testing track before production distribution. APK is suitable for controlled direct testing where policy permits.

Check `fvm flutter build <target> --help` for support of release flags in the pinned SDK and target; avoid inventing flags or weakening build protections. If obfuscation is not supported for a target or prevents diagnostics, document the approved alternative.

## 10. Symbols Management

Store symbol files and obfuscation maps in restricted offline or organization-approved encrypted storage, separately from source control and distributable packages. Use a directory/key scheme that binds symbols to the exact app version, build number, platform, and commit. Maintain an access owner and retention schedule. Verify retrieval before release. Never commit `symbols/`, PDB, dSYM, mapping files, signing material, or user records.

## 11. Troubleshooting

### Flutter and FVM

- **Wrong Flutter version:** run `fvm install` from the repository root and use `fvm flutter --version`.
- **IDE cannot find Flutter:** verify the workspace SDK path resolves to the FVM-managed SDK; reload VS Code.
- **Dependency resolution failure:** check `pubspec.yaml` and lockfile changes, connectivity to package sources, and pinned SDK compatibility. Do not delete or regenerate the lockfile without review.
- **Missing platform support:** inspect `fvm flutter doctor -v` and enable the target only on the correct OS.

### Windows

- **Windows build tools missing:** install/repair Visual Studio 2022 Desktop development with C++ and Windows SDK, then restart terminal/IDE.
- **CMake/MSVC errors:** verify the selected Visual Studio instance and architecture match Flutter's supported toolchain.
- **Native SQLCipher/OpenSSL load errors:** check approved library version, architecture, runtime search path, and packaging; do not disable encryption as a workaround.

### macOS/iOS

- **Xcode license/toolchain errors:** open Xcode, complete first-run install, accept license, check `xcode-select -p`.
- **CocoaPods errors:** verify compatible Ruby/CocoaPods installation and run pod installation only in the relevant platform directory. Avoid deleting lockfiles without cause.
- **Signing failure:** verify team, bundle identifier, entitlements, certificate expiry, and provisioning profile using authorized credentials.
- **Simulator unavailable:** install the requested simulator runtime in Xcode and check `fvm flutter devices`.
- **Notarization rejection:** inspect Apple's rejection details and resolve signing, entitlement, or package issues; do not bypass notarization requirements.

### Git

- **SSH permission denied:** confirm the public key is registered, correct account access, loaded key agent, and remote URL. Never paste private key contents into diagnostics.
- **Line-ending churn:** check `.gitattributes` and local Git `core.autocrlf`; normalize only with reviewed diffs.
- **Sensitive file staged:** stop and unstage it before commit; rotate exposed credentials immediately if already pushed. `.gitignore` does not remove already tracked files.

### Database

- **Cannot open encrypted database:** confirm correct runtime library/SQLCipher build and key handling. Do not inspect or upload production data and do not fall back to plaintext.
- **Migration fails:** preserve the original database, reproduce with a synthetic copy, verify transaction rollback and schema version, then repair through a tested migration.
- **Integrity/authentication failure:** fail closed, preserve evidence safely, and follow incident procedures; do not silently recreate or overwrite user data.

## 12. Quick Reference

### Daily commands

```shell
fvm install
fvm flutter pub get
fvm flutter devices
fvm dart format .
fvm flutter analyze
fvm flutter test --coverage
```

### Build commands

| Target | Command |
|---|---|
| Windows | `fvm flutter build windows --release` |
| macOS | `fvm flutter build macos --release` |
| iOS IPA | `fvm flutter build ipa --release` |
| Android APK | `fvm flutter build apk --release` |
| Android AAB | `fvm flutter build appbundle --release` |
| Linux | `fvm flutter build linux --release` |

Optional shell aliases (add only to the user's local shell profile):

```shell
alias fflutter='fvm flutter'
alias ftest='fvm flutter test'
alias fanalyze='fvm flutter analyze'
```

## 13. No Python virtual environment needed

This is a Flutter/Dart application. Flutter dependencies are managed by Dart Pub (`pubspec.yaml` and `pubspec.lock`) and the Flutter SDK is selected through FVM. A Python virtual environment is not required for normal development. If a separately approved tooling script requires Python, isolate its dependencies for that tool only; do not use Python to manage application dependencies.
