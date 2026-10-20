# Changelog

All notable changes to Insurance Policy Manager are documented here. This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Recovery-key login with mandatory passphrase replacement, independent passphrase verification, biometric enrollment, and versioned backup verifier compatibility.
- Standard Windows desktop runner scaffold for local development and builds.
- Searchable client list with role filters, responsive client details, and create/edit forms.
- Bilingual client-management UI and Archive/Settings navigation placeholders.
- Encrypted backup and restore workflows, including overwrite confirmation and a pre-restore backup.
- Local PDF exports for selected clients with bilingual labels and bundled fonts.
- Backup metadata in Settings and audit records for backup, restore, and PDF export events.

### Changed

- Polished existing screens with tablet/desktop master-detail layouts, skeleton loading states, animated transitions, refresh gestures, and confirmed swipe-to-archive actions.
- Added desktop keyboard shortcuts and a persistent plan-form action bar with asynchronous save progress.

### Deprecated

### Removed

### Fixed

### Security

- PDF exports are not password-encrypted and cannot enforce print/copy restrictions; the export flow requires user acknowledgment before writing the file.
- Restore audit events are written after the next successful unlock because restoring key material locks the key manager.

## [0.1.0] - 2026-10-19

Initial scaffold.

### Added

- Project structure and initial project documentation.
- Flutter analysis options.
- Application theme scaffold.
- Bilingual localization scaffold for Traditional Chinese (`zh-Hant`) and English (`en`).

### Changed

### Deprecated

### Removed

### Fixed

### Security