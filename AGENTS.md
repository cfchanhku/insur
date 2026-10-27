# AGENTS.md

## Insurance Policy Manager (`insur`) — AI Coding Agent Guide

**Last updated:** 2026-10-27

**Read this file and the relevant source before changing code.**

---

## 1. Project Context

Insurance Policy Manager is a local-first Flutter application for managing sensitive insurance and financial information, derived from 「尊貴客戶保障總覽」. It targets Windows, macOS, iOS, Android, and Linux. Treat privacy, security, data integrity, localization, and cross-platform behavior as core requirements.

- Use the Flutter version pinned in `.fvmrc`. Run all Flutter and Dart commands with `fvm flutter` or `fvm dart`; do not rely on a global SDK.
- The application is local-only. Do not add networking, telemetry, crash uploads, cloud storage, or remote synchronization.
- Check `pubspec.yaml`, the source tree, and the platform setup before asserting dependency or platform capabilities. Keep dependency versions and architecture documentation consistent with the repository.

## 2. Critical Rules — Never Violate

### 2.1 Security and privacy

- Never place personally identifiable information (PII), policy or financial data, recovery material, keys, or plaintext secrets in logs, diagnostics, analytics, test output, screenshots, or exception messages.
- Never use `print()` or `debugPrint()` for application diagnostics. Use only a verified structured logging implementation with approved redaction; a declared logger API is not proof that logging is implemented safely.
- Never add network clients, HTTP requests, telemetry, crash uploads, cloud storage, or remote synchronization.
- Never hardcode encryption keys, passwords, tokens, salts, IVs, or recovery secrets. Generate keys securely and store them only through the platform secure-storage abstraction.
- Follow the approved design and existing implementations: SQLCipher with AES-256 for the database, Argon2id for password-based key derivation, and AES-256-GCM for authenticated encryption. Never implement cryptographic primitives or change algorithms or parameters without an approved security-design change and review.
- Authenticate encrypted data. Never silently accept failed authentication, corrupt ciphertext, or failed key derivation.
- Record security- and data-integrity-relevant actions in the tamper-evident audit log without sensitive payloads. Preserve the two-year audit retention requirement.
- Handle biometric credentials and recovery keys securely and per platform. Biometrics must not replace the underlying encryption key.
- Never commit databases, exports, credentials, private keys, signing files, `.env`, or real user data. Keep obfuscation symbols offline and untracked.

### 2.2 Data integrity

- Put related database writes in transactions. Roll back and report failure on errors; do not return success-shaped fallback data.
- Archive business records rather than physically deleting them. Permanent erasure requires an explicitly approved retention or privacy workflow; do not use a UI confirmation as a substitute for that approval.
- Use UUIDs for persistent entity identifiers. Store timestamps in UTC and serialize them consistently as ISO 8601. Maintain creation and update timestamps during writes, migrations, and archive operations.
- Treat migrations as ordered, tested, irreversible transformations of user data. Preserve existing records and archive state.

### 2.3 Internationalization

- Never hardcode user-visible strings in widgets or business logic. Use the generated localization API; `AppLocalizations.of(context)` is configured as non-nullable.
- Add each new user-visible message to English (`lib/l10n/app_en.arb`) and Traditional Chinese (`lib/l10n/app_zh_Hant.arb`), and keep any other configured locale resources consistent.
- Use complete translated messages and typed placeholders; do not concatenate translated fragments.
- After ARB changes, run `fvm flutter gen-l10n`. Never hand-edit generated localization output.
- Check text expansion, accessibility labels, dates, numbers, and layout in both supported app languages.

### 2.4 Cross-platform behavior

- Keep shared Dart code platform-neutral. Encapsulate platform-specific behavior behind existing abstractions; use conditional imports only when they are the established solution.
- Handle secure storage, biometrics, file selection, and database paths explicitly for each supported platform.
- Do not silently omit unsupported behavior. Return a typed, actionable error or expose an intentional capability state.

## 3. Architecture

The current source is organized under `lib/` into `core/`, `features/`, `l10n/`, `providers/`, `router/`, `shared/`, and `theme/`. Feature areas currently include archive, audit, auth, backup, clients, export, home, lock, plans, policies, riders, settings, setup, and splash. Confirm paths in the checkout before extending this layout.

Key boundaries:

- `core/` owns cross-cutting infrastructure such as audit, backup, database, logging, platform, and security.
- `features/<feature>/` owns cohesive feature presentation and application logic. Keep feature internals private to that feature.
- `shared/` contains genuinely reusable models, utilities, and widgets; it must not depend on feature implementations.
- Presentation code should call application or repository abstractions, not raw database or cryptography primitives.
- Keep database and platform implementations behind existing interfaces where practical. Do not introduce a second implementation of an existing abstraction.
- Avoid circular dependencies and cross-feature imports of internal implementation details.
- Generated files are outputs of their declared generators; do not edit them manually.

The current database schema is versioned in `Schema.currentSchemaVersion` (currently version 4). Tables include clients, policies, plans, riders, audit records, schema version history, and application configuration. Always inspect the current schema and migration code; never assume a version or field list from this guide is authoritative.

## 4. PDF Export Requirements

Follow the approved export design and existing PDF implementation. The product reference requirements supplied for this project are:

- A4 landscape with a six-column table: one label column and five policy slots.
- Header: 「尊貴客戶保障總覽」 / “Premium Client Protection Overview”; policy holder name, gender, and date of birth on one row; and review date.
- Include an insured-person row for each applicable plan.
- Sections and fields:
  1. Policy data: insurer, policy number, effective date, first premium date.
  2. Life plan: insured person, plan name, coverage, payment term, coverage period.
  3. Critical illness: insured person, plan name, coverage, payment term, rider name, rider coverage, rider term.
  4. Hospital: insured person, plan name, coverage, term, period, rider name, rider coverage, deductible, waiting period.
  5. Other plans 1–3.
  6. Accident: insured person, plan name, coverage, death/disability, temporary disability, medical.
  7. Savings: insured person, plan name, payment years, cash value, balance, payment method, premium.
- Footer: 「以上為重點摘要，一切详情及细则以各保單條款内容為准」 / “This is a summary; all details are subject to the policy terms.”
- Leave missing values empty; never substitute “N/A”. Paginate at five policies per page and repeat the header. Start each client on a new page. Export one user-selected language per PDF.
- Keep PDF content searchable text; do not rasterize text into images. Use the bundled CJK fonts in `assets/fonts/` as appropriate.
- Protect exported PDFs with AES-256 through the existing `PdfEncryptionService` where password protection is required. Do not expose owner passwords or place secrets in PDF metadata.
- The named reference PDF `Ref-Form-20260914.pdf` was not found in the repository when this guide was updated. Do not claim pixel-perfect parity with it unless the approved reference artifact is available and has been checked.

Treat these as product requirements, not proof that every item is already implemented. Verify behavior and tests before describing it as complete.

## 5. Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Types, classes, enums | `UpperCamelCase` | `PolicyRepository` |
| Variables, parameters, methods | `lowerCamelCase` | `recoveryKey` |
| Constants | `lowerCamelCase` | `defaultRetentionDays` |
| Dart files and directories | `lower_snake_case` | `policy_repository.dart` |
| Database columns | `snake_case` | `created_at` |
| Localization keys | descriptive `lowerCamelCase` | `recoveryKeyTitle` |
| Test files | `<subject>_test.dart` | `policy_repository_test.dart` |

Use the established suffixes and patterns in the relevant feature. Do not introduce a new state-management, dependency-injection, or result convention for a single feature.

## 6. Code Style

- Follow `analysis_options.yaml` and Dart formatter output. Do not suppress diagnostics without an approved reason.
- Follow the repository's existing import conventions and configured analyzer rules.
- Prefer `const` constructors, immutable values, cohesive methods, explicit public API types, and exhaustive switches.
- Avoid `dynamic`, unchecked casts, unnecessary null assertions, magic values, and duplicate abstractions.
- Keep widgets focused. Separate state transitions and data access from rendering.
- Document public APIs with `///` comments when their contract is not self-evident.
- After every `await` in a widget state method, handle the possibility that the widget is no longer mounted before using its context.
- Catch only expected exception types at appropriate boundaries. Surface failures explicitly; do not hide errors behind defaults or empty results.
- Log only safe event descriptions and approved redacted metadata. Never include a policy, user input, identity-revealing identifier, key, or secret in a log or error.

Security-critical changes in `core/security/`, `core/backup/`, `core/audit/`, or database code require relevant tests, including known vectors, tamper cases, rollback behavior, or migration coverage as applicable. Never invent cryptographic choices or parameters; request maintainer direction if a change would alter an approved security property.

## 7. Testing and Validation

Use synthetic data only. Tests and fixtures must not contain real client data, production secrets, or identifying values. Use deterministic fakes and disposable temporary databases.

Coverage goals:

| Area | Target |
|---|---:|
| Core security | 95% |
| Database | 90% |
| Business logic | 80% |
| UI | 60% |
| Overall | 80% |

Cover success, invalid input, failures, edge cases, and regressions. Add tests for transaction rollback, migration behavior, platform-specific branches, localization coverage, and audit-chain tampering where relevant.

Run the smallest checks that cover the change. Before submitting a complete change, run:

```powershell
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
```

Report the exact checks run and any limitations. Do not claim tests pass if they were not run.

## 8. Common Tasks

### Add a feature

1. Confirm user-visible behavior and security/data-classification impact.
2. Add the feature under `lib/features/<feature>/`, following existing module patterns.
3. Keep storage and platform behavior behind existing core abstractions.
4. Add English and Traditional Chinese localization strings and regenerate localization output.
5. Add unit, widget, or integration tests with synthetic data, including failure cases.
6. Add audit entries for relevant mutations. Update directly related documentation and `CHANGELOG.md` when appropriate.

### Add a database migration

1. Inspect the current schema version and ordered migration mechanism.
2. Add a new migration; never rewrite a released migration.
3. Make the migration transactional and preserve user data, archive state, and timestamps.
4. Test a fresh database, the prior schema version, successful migration, and rollback/failure behavior.
5. Do not weaken SQLCipher or key handling to simplify tests.

### Add a field to a model

1. Determine whether the field is sensitive and requires encryption.
2. Add a safe migration and update the model's serialization and value semantics following existing patterns.
3. Update repository read/write paths, forms, validation, localization, and PDF output if applicable.
4. Add synthetic regression tests for storage, presentation, and export behavior.

### Add a dependency

Prefer the SDK or an already approved package. Assess maintenance, licensing, platform coverage, transitive dependencies, and security implications. Use the narrowest compatible version constraint, update the lockfile, and document why the dependency is needed. Never add telemetry, networking, or cloud behavior without explicit product and security approval.

## 9. Do Not

- Do not use `print()`, production `debugPrint()`, `dynamic`, or unchecked casts.
- Do not hardcode user-visible strings, secrets, or reusable theme colors outside the established theme system.
- Do not add TODOs without an issue reference, comment out code instead of removing it, or add unexplained magic numbers.
- Do not log model contents or sensitive identifiers.
- Do not modify released migrations or generated files by hand.
- Do not add dependencies without reviewing compatibility and security implications.
- Do not bypass repository boundaries, audit logging, authorization, input validation, or secure storage.
- Do not commit without running the relevant analyzer and tests.
- Do not bypass pre-commit hooks without an approved, documented reason.

## 10. Security Checklist

Before committing:

- [ ] No PII, policy or financial data, credentials, keys, database files, exports, symbols, or secrets are staged.
- [ ] No sensitive values enter logs, errors, test output, fixtures, or screenshots.
- [ ] No network, cloud, or telemetry behavior has been added.
- [ ] Key derivation, AES-256-GCM, SQLCipher, secure storage, and biometric boundaries follow the approved designs.
- [ ] Tampered or invalid encrypted input fails safely; failures are not silently accepted.
- [ ] Related writes are transactional; archive and timestamp behavior is correct.
- [ ] Required security actions are recorded in the tamper-evident audit log without sensitive payloads.
- [ ] English and Traditional Chinese resources are complete; relevant negative and regression cases are tested.
- [ ] `fvm flutter analyze` and relevant tests pass; security-sensitive changes received the required review.

## 11. Build and Run Commands

Run commands from the repository root with FVM. Builds require the target platform toolchain. Keep signing credentials local and untracked.

| Target | Build machine | Command |
|---|---|---|
| Windows desktop | Windows 11 | `fvm flutter run -d windows` / `fvm flutter build windows` |
| macOS desktop | macOS | `fvm flutter run -d macos` / `fvm flutter build macos` |
| iOS | macOS with Xcode | `fvm flutter run -d <device-id>` / `fvm flutter build ios` |
| Android APK | Windows or macOS with Android SDK | `fvm flutter run -d <device-id>` / `fvm flutter build apk` |
| Android App Bundle | Windows or macOS with Android SDK | `fvm flutter build appbundle` |
| Linux desktop | Linux | `fvm flutter run -d linux` / `fvm flutter build linux` |

For release builds, follow `docs/RELEASE_CHECKLIST.md` and the target platform's signing requirements. Store obfuscation symbols offline and never commit or upload them.

## 12. AI Agent Notes

### When implementing

1. Read this file plus the relevant source, tests, and documentation.
2. Check `.fvmrc` and `analysis_options.yaml`.
3. Confirm existing architecture, platform behavior, localization, and security boundaries rather than assuming this guide proves implementation.
4. Make focused changes, preserve intended behavior, and add tests.
5. Update both locales and audit relevant mutations.
6. Never violate the security and data-integrity rules in section 2.

### When reviewing

1. Check for sensitive data in logs, errors, tests, and fixtures.
2. Check localization coverage, authorization, audit entries, data integrity, and regression tests.
3. For PDF changes, verify searchable text and the stated export requirements.

### When refactoring

1. Preserve behavior unless a functional change was explicitly requested.
2. Update relevant tests and localization resources.
3. Run analysis and tests before reporting completion.

When uncertain, ask rather than guess. If a requirement conflicts with security or privacy rules, stop and request maintainer direction.
