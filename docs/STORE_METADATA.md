# Store Metadata — Draft

This is draft copy, not confirmation that a store release is ready. Windows,
macOS, and iOS host projects are present, but store distribution still requires
platform behavior, bundle identifiers, privacy disclosures, and legal
ownership to be reviewed.

## Product identity

| Field | Draft |
|---|---|
| English display name | Insurance Policy Manager |
| Traditional Chinese display name | 保單管理系統 |
| Proposed reverse-DNS identifier | `com.insur.app` |
| iOS SKU | `INSUR_POLICY_MANAGER_001` (replace if already used) |
| Category | Business / Productivity (confirm with each store) |
| Price and distribution | Publisher decision required |

The proposed identifier has not been verified as owned or available. Configure
it consistently in each native platform project only after confirming
ownership and migration implications.

## Short description

Manage insurance records locally with encrypted storage, encrypted backups,
and password-protected PDF exports.

## Full description

Insurance Policy Manager helps organize client, policy, plan, and rider
information on your device.

- Organize clients and related insurance records.
- Protect the local vault with a passphrase, encrypted database storage, and
  field-level encryption.
- Create an offline recovery key and use it to regain access and set a new
  passphrase.
- Create encrypted backups and restore with a pre-restore safety backup.
- Export selected client information as password-protected encrypted PDFs.
- Use Traditional Chinese or English, with light, dark, or system themes.
- Review tamper-evident audit history.

The application does not provide biometric unlock in this release. Scheduled
automatic backups are not active; backups must be created manually. Keep your
passphrase, recovery key, backup files, and export passwords secure. If both
your passphrase and recovery key are lost, the vault data cannot be recovered
by the maintainers.

## iOS fields to complete

- App name, subtitle, primary language, category, SKU, age rating, pricing, and
  availability territories.
- App privacy questionnaire based on the actual release build and current
  store rules.
- Support URL, privacy-policy URL, copyright owner, review contact, and review
  notes.
- Screenshots captured from the final app with synthetic data only.
- Bundle identifier availability and signing team confirmation.

## Android fields to complete

- App name, short/full descriptions, category, content rating, pricing, and
  availability territories.
- Data safety form and privacy-policy URL based on the final release build.
- Support contact, developer identity, signing/upload-key policy, and package
  identifier availability.
- Phone/tablet screenshots captured from the final app with synthetic data.

## Screenshot capture checklist

Use only synthetic records and inspect every screenshot for PII, device
notifications, account details, and filesystem paths.

- Home/client list.
- Client detail with synthetic policies.
- Plan detail or form with a synthetic rider.
- Settings and audit viewer.
- Export screen.
- Optional dark-theme capture.

Capture final store-required sizes from actual supported devices or simulators;
the required dimensions and device families can change.

## Review notes

Explain that the application stores records locally, has no service account or
remote sync, and requires a user-created passphrase. Give store reviewers a
synthetic-data test flow for the final native build. Do not promise
biometric unlock, unsupported platform coverage, or non-existent server
accounts.

## iOS privacy manifest

The iOS host is present. Audit the app and every native dependency against
Apple's current required-reason API rules, then add or update
`PrivacyInfo.xcprivacy` before App Store submission. Do not guess declarations;
verify them against the final dependency versions and native API usage.
