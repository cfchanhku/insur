# Changelog

All notable changes to Insurance Policy Manager are documented here. The
format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-20

### Added

- Local client, policy, plan, and rider management, including archive and
  restore workflows.
- Passphrase-protected vault using a randomly generated master key wrapped by
  an Argon2id-derived key.
- SQLCipher database encryption and AES-256-GCM field protection.
- Offline recovery-key setup and recovery with required passphrase replacement.
- Encrypted backups and safe restore flow with a pre-restore backup.
- Password-protected, AES-256 encrypted PDF exports with configurable printing
  permission and accessible text extraction.
- Traditional Chinese and English interface, theme settings, and responsive
  layouts.
- Tamper-evident audit history and audit viewer.
- Windows desktop build configuration.

### Security

- Biometric enrollment preference is available, but biometric unlock is
  deferred until platform-protected key access is implemented.
- Automatic backup scheduling is not active; backups must be started manually.
- Legacy key credentials migrate after a successful passphrase unlock. Keep a
  verified backup before upgrading any installation containing data.

### Release limitations

- This repository currently contains a Windows desktop host project only.
  macOS, iOS, Android, and Linux release artifacts are not available from this
  source tree yet.
- Windows packages are unsigned unless a release operator signs them with an
  authorized code-signing certificate.
- PDF encryption uses Syncfusion; review [LICENSE-SYNCFUSION.md](LICENSE-SYNCFUSION.md)
  and complete the applicable license registration before distribution.
