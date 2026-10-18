# Insurance Policy Manager (insur)

Insurance Policy Manager is a fully local, encrypted, cross-platform application for managing sensitive insurance policy data derived from the 「尊貴客戶保障總覽」 (Premium Client Protection Overview). It is designed to keep client, policy, plan, and rider information on the user's device, with no cloud account, synchronization, or server.

## Key characteristics

- **100% local:** the application stores and processes its data on the user's device; no cloud service is used.
- **Encrypted database:** SQLCipher with AES-256 database encryption.
- **Key protection:** Argon2id key derivation and AES-256-GCM authenticated encryption for protected data and backups.
- **Authentication and recovery:** biometric authentication where supported, plus an offline recovery key.
- **Bilingual interface:** Traditional Chinese (`zh-Hant`) and English (`en`).
- **Tamper-evident audit log:** hash-chained audit records with a two-year retention policy.

These are the project's security and product requirements. Review [SECURITY.md](SECURITY.md) for the design summary and [AGENTS.md](AGENTS.md) for implementation constraints.

## Target platforms

| Target | Build machine |
|---|---|
| Windows desktop | Windows 11 |
| macOS desktop | macOS |
| iOS | macOS with Xcode |
| Android | Windows or macOS with Android SDK |
| Linux desktop | Linux |

## Development setup

- **Windows 11:** primary development environment and required machine for Windows desktop builds. Install Git, VS Code, FVM, Flutter's Windows desktop prerequisites (including Visual Studio with the Desktop development with C++ workload), and the Android SDK if building Android.
- **macOS:** required for iOS and macOS builds. Install Git, VS Code, FVM, Xcode and its command-line tools; install CocoaPods for iOS dependencies. Install the Android SDK if building Android.
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

### macOS

```bash
git clone <repository-url>
cd insur
fvm install
fvm flutter pub get
fvm flutter run -d macos
```

Replace `<repository-url>` with the private repository URL supplied by the project maintainer. If platform tooling is not yet installed, run `fvm flutter doctor` and complete the requirements for your target.

## Project structure

Top-level directories planned for the Flutter application:

```text
android/          Android host application
assets/           Fonts, images, and other bundled assets
docs/             Project and development documentation
integration_test/ Cross-platform integration tests
ios/              iOS host application
lib/              Flutter application source
macos/            macOS host application
test/             Unit and widget tests
windows/          Windows host application
```

## Build commands

Run commands from the repository root with the pinned SDK:

| Target | Command |
|---|---|
| Windows desktop | `fvm flutter build windows` |
| macOS desktop | `fvm flutter build macos` |
| iOS | `fvm flutter build ios` |
| Android APK | `fvm flutter build apk` |
| Android App Bundle | `fvm flutter build appbundle` |
| Linux desktop | `fvm flutter build linux` |

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
