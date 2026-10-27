# Insurance Policy Manager (insur)

Insurance Policy Manager is a local, encrypted application for managing sensitive insurance policy data derived from the 「尊貴客戶保障總覽」 (Premium Client Protection Overview). The repository includes Windows and macOS desktop hosts and an iOS host for iPhone and iPad. Android and Linux remain planned targets. The application is designed to keep client, policy, plan, and rider information on the user's device, with no cloud account, synchronization, or server.

## Key characteristics

- **Local-first:** the application stores and processes its data on the user's device; no cloud service is used.
- **Encrypted database:** SQLCipher with AES-256 database encryption.
- **Key protection:** Argon2id key derivation and AES-256-GCM authenticated encryption for protected data and backups.
- **Authentication and recovery:** passphrase-protected access and an offline recovery key. Biometric enrollment is available, but biometric unlock is deferred.
- **Bilingual interface:** Traditional Chinese (`zh-Hant`) and English (`en`).
- **Tamper-evident audit log:** hash-chained audit records with a two-year retention policy.

These are the project's security and product requirements. Review [SECURITY.md](SECURITY.md) for the design summary and [AGENTS.md](AGENTS.md) for implementation constraints.

## Platform readiness

Windows and macOS desktop hosts and the iOS host are present. iOS targets
iPhone and iPad and requires iOS 15 or newer. Host presence and successful
development builds do not constitute release approval; signing, privacy
disclosures, clean-device behavior, and distribution packaging still require
platform-specific validation. See [docs/BUILD_MATRIX.md](docs/BUILD_MATRIX.md)
and [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

## Development setup

- **Windows 11:** required for Windows desktop builds. Install Git, VS Code, FVM, Flutter's Windows desktop prerequisites (including Visual Studio with the Desktop development with C++ workload).
- **macOS:** required for iOS and macOS builds. Install Git, VS Code, FVM, Xcode and its command-line tools, and CocoaPods.
- **GitHub:** source-code hosting and collaboration only. The application does not upload user data to GitHub or any other cloud service.

Use Flutter through FVM so local commands follow the version pinned in [.fvmrc](.fvmrc). Do not commit device data, keys, exports, credentials, or other secrets; see [.gitignore](.gitignore) and [SECURITY.md](SECURITY.md).

## Quick start

### Windows 11

```powershell
git clone <repository-url>
Set-Location insur
fvm install
fvm flutter pub get
fvm flutter run -d windows
```

### macOS and iOS

On macOS, run `fvm flutter run -d macos` for the desktop app or
`fvm flutter run -d ios` with an iOS simulator or connected iPhone/iPad.
Windows builds must run on Windows with the required Visual Studio workload.
Android and Linux host projects are not present.

Replace `<repository-url>` with the private repository URL supplied by the project maintainer. If platform tooling is not yet installed, run `fvm flutter doctor` and complete the requirements for your target.

## Project structure

Top-level directories planned for the Flutter application:

```text
assets/           Fonts, images, and other bundled assets
docs/             Project and development documentation
integration_test/ Cross-platform integration tests
ios/              iOS host application (iPhone and iPad)
lib/              Flutter application source
macos/            macOS host application
test/             Unit and widget tests
windows/          Windows host application
```

## Build commands

Run commands from the repository root with the pinned SDK:

| Target | Current status |
|---|---|
| Windows desktop | `fvm flutter build windows --release` (build on Windows) |
| macOS desktop | `fvm flutter build macos --release` (build on macOS) |
| iOS Simulator | `fvm flutter build ios --simulator --no-codesign` |
| iOS device / IPA | `fvm flutter build ios` / `fvm flutter build ipa` (signing required) |
| Android APK / App Bundle | Host project not present |
| Linux desktop | Host project not present |

Platform-specific toolchains and signing configuration are required. iOS builds require macOS and Xcode; do not commit signing credentials or provisioning secrets.

## Security notice

**NEVER commit** `*.db`, `*.enc`, `*.key`, `*.pem`, `*.p12`, `symbols/`, `secrets/`, or `.env` files. Treat all policy, client, financial, and authentication data as sensitive. Do not use real client data in issues, pull requests, logs, screenshots, or test fixtures.

## Project documents

- [CONTRIBUTING.md](CONTRIBUTING.md) — development and review workflow
- [AGENTS.md](AGENTS.md) — persistent project instructions for AI coding assistants
- [SECURITY.md](SECURITY.md) — security design and vulnerability reporting
- [docs/](docs/) — project documentation
  - [Implementation plan](docs/IMPLEMENTATION_PLAN.md)
  - [Wireframes and UI specifications](docs/WIREFRAMES.md)
  - [Development setup](docs/DEVELOPMENT_SETUP.md)
  - [Build matrix](docs/BUILD_MATRIX.md)
  - [Multi-app setup](docs/MULTI_APP_SETUP.md)

## License

Proprietary — Internal Use Only.
