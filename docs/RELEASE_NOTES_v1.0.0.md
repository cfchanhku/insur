# Insurance Policy Manager 1.0.0

**Release date:** 2026-10-20  
**Version:** 1.0.0 (build 1)

Insurance Policy Manager is a local-first application for organizing insurance
clients and their policies, plans, and riders. The Windows build stores app
data on the device and provides encrypted backups and PDF exports.

## What’s included

- Manage client, policy, plan, and rider records, with archive and restore.
- Protect the local vault with a passphrase, SQLCipher, and AES-256-GCM
  field-level encryption.
- Create an offline recovery key and use it to regain access and set a new
  passphrase.
- Create encrypted backups and restore them with a pre-restore safety backup.
- Export selected client information as an AES-256 password-protected PDF.
- Use the interface in Traditional Chinese or English, with light, dark, or
  system theme settings.
- Review tamper-evident audit history.

## Important security and availability notes

- **Keep your recovery key offline and your backup passphrase safe.** The
  maintainers cannot recover vault data if both your passphrase and recovery
  key are lost.
- Biometric enrollment settings are present, but biometric unlock is not
  currently available.
- Scheduled automatic backups are not active. Create backups manually.
- The repository currently has a Windows host project only. Builds and store
  releases for macOS, iOS, Android, and Linux are not ready.
- Windows packages are unsigned unless explicitly signed by the release
  operator; Windows may show a SmartScreen warning.
- PDF encryption uses Syncfusion. See
  [LICENSE-SYNCFUSION.md](../LICENSE-SYNCFUSION.md) for the license notice.

## Windows installation

When the release ZIP is published, extract its contents to a folder you
control and run `insur.exe`. The ZIP contains the Flutter runner and required
runtime files; do not copy only the executable.

## Upgrade

Make and verify an encrypted backup before upgrading. Existing legacy key
credentials are migrated after a successful unlock. Test upgrades with a
disposable copy of the database before distributing this release to users.

## Release support

The release owner should publish an approved support and security-reporting
contact before distributing this build. Do not use sample client information
in screenshots or demonstrations.
