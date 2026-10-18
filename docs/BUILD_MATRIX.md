# Insurance Policy Manager — Build Matrix

**Version:** 1.0  
**Classification:** Proprietary — Internal Use Only  
**Purpose:** Quick reference for supported build hosts, commands, artifacts, and release checks.

All Flutter commands must run through FVM from the repository root. Build targets and packaging formats remain subject to platform validation and release approval. Never place application data, keys, signing assets, or symbols in Git.

## 1. Machine → Target matrix

| Build machine | Windows | macOS | iOS | Android | Linux |
|---|---:|---:|---:|---:|---:|
| Windows 11 | **Required** | — | — | Optional | — |
| macOS | — | **Required** | **Required** | Optional | — |
| Linux | — | — | — | Optional | **Required** |

Windows is the primary development workstation and required for Windows builds. Apple builds require macOS. Android builds are optional on Windows/macOS once Android SDK and signing tools are installed. Linux builds require a configured Linux machine and are not produced by the primary two-machine setup.

## 2. Build command reference

| Target | Machine | Command |
|---|---|---|
| Windows desktop | Windows 11 | `fvm flutter build windows --release` |
| macOS desktop | macOS | `fvm flutter build macos --release` |
| iOS IPA | macOS with Xcode | `fvm flutter build ipa --release` |
| Android APK | Windows/macOS with Android SDK | `fvm flutter build apk --release` |
| Android App Bundle | Windows/macOS with Android SDK | `fvm flutter build appbundle --release` |
| Linux desktop | Linux with desktop dependencies | `fvm flutter build linux --release` |

For supported targets, release obfuscation and symbol splitting may be enabled with `--obfuscate --split-debug-info=<restricted-symbol-path>`. Verify flags with the pinned SDK and preserve matching symbols. Configure platform signing and packaging separately.

## 3. Output locations

Paths are Flutter's conventional build outputs; actual contents can vary by SDK, project configuration, and packaging step.

| Target | Typical build path | Packaged as |
|---|---|---|
| Windows desktop | `build\windows\x64\runner\Release\` | Runner bundle; create approved installer/package separately |
| macOS desktop | `build/macos/Build/Products/Release/` | `.app`; optionally package as signed/notarized `.dmg` or `.pkg` |
| iOS | `build/ios/ipa/` | Signed `.ipa` |
| Android APK | `build/app/outputs/flutter-apk/` | `.apk` |
| Android App Bundle | `build/app/outputs/bundle/release/` | `.aab` |
| Linux desktop | `build/linux/x64/release/bundle/` | Bundle; package into approved AppImage/deb/rpm as configured |

Do not distribute raw build folders until packaging, signing, dependency inclusion, and clean-install verification are complete.

## 4. Distribution channels

| Target | Channel | Requirements |
|---|---|---|
| Windows | Approved internal distribution / managed installer | Authenticode signing as required, package integrity, supported Windows validation |
| macOS | Direct controlled distribution or Mac App Store (decision required) | Developer ID/App Store signing, notarization for applicable direct distribution, hardened runtime/entitlements review |
| iOS | App Store Connect / TestFlight | Apple Developer membership, provisioning, App Review metadata, privacy disclosures, device testing |
| Android | Google Play internal/production tracks or approved direct distribution | Protected upload key, Play App Signing policy where used, AAB validation, privacy and store disclosures |
| Linux | Approved internal repository or selected package distribution | Package signing and tested distribution-specific dependencies; channel decision required |

Distribution choices, supported OS versions, and organizational legal/privacy disclosures must be approved before release.

## 5. Symbols storage

| Target | Typical symbol artifacts | Storage |
|---|---|---|
| Windows | Flutter split-debug-info output, PDB files if generated | Restricted offline/encrypted symbol archive |
| macOS | Flutter split-debug-info output, dSYM bundles | Restricted offline/encrypted symbol archive |
| iOS | Flutter split-debug-info output, dSYM bundles | Restricted offline/encrypted symbol archive |
| Android | Flutter split-debug-info output; native symbols/mapping files as applicable | Restricted offline/encrypted symbol archive |
| Linux | Flutter split-debug-info output, native debug symbols if produced | Restricted offline/encrypted symbol archive |

Name each symbol set by app version, build number, platform, and commit. Restrict access, test retrieval, document retention, and never commit symbols or obfuscation maps.

## 6. Build time estimates

Indicative clean build times on a modern developer workstation; not service-level objectives. First builds, dependency downloads, code signing, and packaging can take substantially longer.

| Target | Typical estimate |
|---|---:|
| Windows desktop | 3–10 minutes |
| macOS desktop | 3–10 minutes |
| iOS archive/IPA | 5–20 minutes |
| Android APK/AAB | 3–15 minutes |
| Linux desktop | 3–10 minutes |

Record actual baseline times after toolchains and dependencies are stabilized.

## 7. Release checklist

### Windows 11

- [ ] Confirm release branch, version/build number, and approved commit.
- [ ] `fvm flutter analyze` and relevant tests pass; perform a clean release build.
- [ ] Verify Windows SDK, Visual Studio toolchain, SQLCipher runtime, and packaged native dependencies.
- [ ] Confirm database remains encrypted and errors fail closed; use synthetic test data.
- [ ] Sign the approved package with authorized certificate where required.
- [ ] Test installation, upgrade, startup, backup/restore, archive, and uninstall on supported Windows versions.
- [ ] Store symbols securely and verify package hash/provenance.
- [ ] Scan staged files and package for secrets, local databases, logs, and test data.

### macOS (macOS and iOS)

- [ ] Confirm release branch, version/build number, supported OS targets, and approved commit.
- [ ] `fvm flutter analyze` and tests pass; build on a supported macOS/Xcode host.
- [ ] Verify secure-storage, biometric, file, database, and migration behavior on simulators and physical devices where applicable.
- [ ] Review iOS/macOS entitlements, privacy disclosures, permission prompts, and sandbox behavior.
- [ ] Sign with authorized Apple identity; notarize/staple applicable macOS direct-distribution packages.
- [ ] For iOS, validate archive and TestFlight workflow, metadata, and App Review requirements.
- [ ] Run synthetic-data install/upgrade, recovery, encrypted backup/restore, and accessibility/localization checks.
- [ ] Archive matching dSYM/split-debug-info files securely; verify package integrity.
- [ ] Confirm no signing credentials, provisioning profiles, user data, or symbols were committed.

## 8. Version numbering

Use Semantic Versioning for product releases: `MAJOR.MINOR.PATCH` (`0.y.z` during pre-1.0 development). Increment major for incompatible data/API behavior, minor for backward-compatible functionality, and patch for backward-compatible fixes. A schema migration is not automatically a major release, but must have documented forward compatibility and recovery behavior.

Maintain a monotonically increasing platform build number (Android `versionCode`, Apple build number, and equivalent platform package revision) independent of the human-readable version. Record version, build number, commit, toolchain, and artifact hashes in release evidence.
