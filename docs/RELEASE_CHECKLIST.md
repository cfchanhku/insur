# Release Checklist — v1.0.0

Release preparation checklist. Unchecked items are not release approval.

## Product and governance

- [ ] Confirm publisher legal name, support contact, privacy contact, license,
  territories, price, and distribution channels.
- [ ] Confirm the proposed `com.insur.app` identifier is owned/available before
  configuring platform projects.
- [ ] Review [PRIVACY.md](../PRIVACY.md) with the responsible privacy/legal
  reviewer and publish a maintained policy URL.
- [ ] Review Syncfusion license terms, registration, and eligibility in
  [LICENSE-SYNCFUSION.md](../LICENSE-SYNCFUSION.md).
- [ ] Review release notes and store copy against the final binary; do not claim
  biometric unlock or scheduled backups.

## Source and validation

- [ ] Confirm clean, approved release commit and review the complete diff.
- [ ] Verify `version: 1.0.0+1` and release changelog.
- [ ] Run `fvm dart format --output=none --set-exit-if-changed .`.
- [ ] Run `fvm flutter analyze`.
- [ ] Run `fvm flutter test --coverage --concurrency=1` with required native
  libraries available.
- [ ] Test database/key migration, recovery, backup/restore, PDF encryption,
  localization, accessibility, and archive/delete behavior using synthetic
  data.
- [ ] Scan source and distributables for secrets, user data, databases,
  credential files, debug output, and symbols.

## Windows

- [ ] Build/package on the supported Windows host with
  `.\scripts\build-windows.ps1`.
- [ ] Confirm the ZIP contains the complete runner bundle and SHA-256 file.
- [ ] Decide whether to sign; if signing, use an authorized certificate and
  verify the signature and timestamp.
- [ ] Install and test on clean supported Windows machines; verify upgrade,
  database location, SQLCipher runtime, backup/restore, and uninstall.
- [ ] If unsigned, document the expected SmartScreen warning.

## Other platforms — currently blocked

The repository does not contain `android/`, `ios/`, `macos/`, or `linux/`
platform projects. Do not mark these targets ready or run platform packaging
steps until those projects and their native integrations exist.

- [ ] Add and validate Android host, release signing, APK/AAB, Play Console
  disclosures, and clean-device installation.
- [ ] Add and validate iOS host, bundle ID, signing/provisioning, privacy
  manifest, App Store metadata, and TestFlight installation.
- [ ] Add and validate macOS host, signing identity, hardened runtime and
  entitlements, notarized DMG, and Gatekeeper installation.
- [ ] Add and validate Linux host, native dependencies, package metadata,
  `.deb`/tarball packaging, and installation on supported distributions.

## Publication

- [ ] Capture final store screenshots using synthetic data.
- [ ] Verify artifact hashes from a separate download.
- [ ] Archive matching symbols securely; do not publish or commit them.
- [ ] Obtain release-owner approval before creating/pushing a tag or publishing
  artifacts.

CI/CD is intentionally not included; builds remain manual until a release
owner approves credentials, runners, and signing policy.
