# Build and Platform Readiness

All project Flutter commands use FVM and the version in `.fvmrc`. This matrix
describes the checked-in repository state; a planned target is not a supported
release target until its host project, native integrations, signing, packaging,
and install/upgrade behavior have been implemented and validated.

## Platform status

| Platform | Host project present | Release status |
|---|---:|---|
| Windows desktop | Yes | Buildable; package with `scripts/build-windows.ps1`. Clean-machine release validation and authorized signing remain required. |
| macOS desktop | No | Not buildable from this repository yet. |
| iOS | No | Not buildable from this repository yet. |
| Android | No | Not buildable from this repository yet. |
| Linux desktop | No | Not buildable from this repository yet. |

## Windows

Build and package from PowerShell:

```powershell
.\scripts\build-windows.ps1
```

The script calls `fvm flutter build windows --release`, packages the complete
runner directory as a portable ZIP, and writes a SHA-256 sidecar beneath
`build\release`. Signing is optional and signs the runner executable using a
certificate already installed in the current user's Personal certificate
store. The ZIP is not signed.

Validate the package on a clean supported Windows machine with no Flutter SDK.
Confirm required runtime DLLs are included, app startup and local database
paths work, backups restore, and upgrade behavior preserves data. Unsigned
executables may trigger SmartScreen warnings.

## Planned platform build commands

These commands are references only; Flutter cannot build targets whose host
project directories have not been generated and validated:

| Target | Required host |
|---|---|
| macOS | macOS with Xcode and an Apple Developer signing identity |
| iOS | macOS with Xcode, signing/provisioning, and App Store configuration |
| Android APK/AAB | Android host project, Android SDK, and protected release signing |
| Linux | Linux host project, desktop dependencies, and distribution packaging |

Do not create release artifacts, store submissions, or privacy manifests for
these targets until their platform integrations and API disclosures have been
reviewed.

## Release evidence and symbols

Record version, build number, source commit, toolchain versions, signing state,
artifact hash, and clean-install results for each produced package. Keep
obfuscation/debug symbols and signing material in restricted storage; never
commit them or distribute them alongside public binaries.

See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for release gates and blocked
platform tasks.
