# AI Coding Assistant Context

| Property | Value |
|---|---|
| Project | Insurance Policy Manager (`insur`) |
| Version | `0.1.0` (initial scaffold) |
| Stack | Flutter / Dart; Flutter SDK pinned with FVM |
| Platforms | Windows, macOS, iOS, Android, Linux desktop |
| Classification | Proprietary; handles highly sensitive personal, financial, and insurance data |

This is a local-first insurance policy manager derived from 「尊貴客戶保障總覽」. Treat security, privacy, data integrity, bilingual support, and cross-platform behavior as core requirements.

## 1. Critical Rules (Never Violate)

### Security and privacy

- Never place personally identifiable information (PII), policy data, recovery material, cryptographic keys, or plaintext secrets in logs, diagnostics, analytics, test output, screenshots, or exception messages.
- Never use `print()` for application diagnostics. Use the approved structured logging abstraction only after confirming that sensitive values are redacted.
- Do not add network clients, HTTP requests, telemetry, crash uploads, cloud storage, or remote synchronization. The application is local-only.
- Never hardcode encryption keys, passwords, tokens, salts, or recovery secrets. Generate keys securely and store them only through the platform secure-storage abstraction.
- Use the approved cryptographic libraries and design: SQLCipher with AES-256 for the database, Argon2id for password-based key derivation, and AES-256-GCM for authenticated encryption. Never implement cryptographic primitives yourself or change algorithms/parameters without an approved security-design change and review.
- Authenticate encrypted data; never silently accept failed authentication, corrupt ciphertext, or failed key derivation.
- Record security- and data-integrity-relevant actions in the tamper-evident audit log. Do not log sensitive payloads. Preserve the two-year audit retention requirement.
- Use secure, platform-aware handling for biometric credentials and recovery keys; biometrics must not replace the underlying encryption key.

### Data integrity

- Put related database writes in transactions. On any error, roll back and report failure; never return success-shaped fallback data.
- Archive records rather than physically deleting business records unless an approved retention or privacy workflow specifically requires permanent erasure.
- Use UUIDs for persistent entity identifiers; do not use sequential IDs that disclose record counts or ordering.
- Store timestamps in UTC and serialize them consistently (ISO 8601). Keep creation and update timestamps accurate, including migrations and archive operations.
- Treat database migrations as irreversible production data transformations: make them ordered, tested, and safe for existing user data.

### Localization

- Never hardcode user-visible strings in widgets or business logic. Use the localization system.
- Add every new user-visible message to both Traditional Chinese (`zh-Hant`) and English (`en`) ARB files.
- Do not concatenate translated fragments to form sentences; use complete localized messages and typed placeholders.
- Check text expansion, accessibility labels, dates, numbers, and direction/layout behavior in both locales.

### Flutter version and cross-platform support

- Run Flutter and Dart commands using `fvm flutter` and `fvm dart`. The pinned version is in `.fvmrc`; do not rely on a machine's global SDK.
- Keep shared Dart code platform-neutral. Encapsulate platform-specific behavior behind abstractions and use conditional imports only where they are the established solution.
- Handle platform capabilities (secure storage, biometrics, file selection, database paths) explicitly. Do not assume that mobile and desktop APIs or permissions are interchangeable.
- Do not silently omit unsupported platform behavior. Return a typed, actionable error or expose a deliberate capability state.

## 2. Project Structure

Expected application source layout:

```text
lib/
├── main.dart
├── app.dart
├── l10n/
│   └── (generated localization code; do not hand-edit generated files)
├── core/
│   ├── audit/
│   ├── backup/
│   ├── database/
│   ├── errors/
│   ├── logging/
│   ├── platform/
│   ├── security/
│   └── time/
├── features/
│   ├── audit/
│   ├── auth/
│   ├── backup/
│   ├── clients/
│   ├── export/
│   ├── plans/
│   ├── policies/
│   ├── riders/
│   └── settings/
└── shared/
    ├── models/
    ├── utils/
    └── widgets/
```

Layering rules:

1. `core/` owns cross-cutting infrastructure and domain-independent security, persistence, platform, and error abstractions.
2. `features/<feature>/` owns that feature's presentation, application/business logic, and feature-specific data integration. Keep feature internals cohesive.
3. `shared/` contains genuinely reusable presentation/model utilities; it must not become a dumping ground or depend on feature implementations.
4. Presentation code calls application/domain services, not raw database or cryptography primitives.
5. Database and platform-specific implementations sit behind interfaces so business logic can be tested without a device or production data.
6. Avoid circular dependencies and cross-feature imports of internal implementation details. Promote a shared interface only when multiple consumers need it.
7. Generated files are outputs of their declared generators and must not be edited manually.

## 3. Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Types, classes, enums, extensions | `UpperCamelCase` | `PolicyRepository` |
| Variables, parameters, methods | `lowerCamelCase` | `recoveryKey` |
| Constants | `lowerCamelCase` (follow Dart style) | `defaultRetentionDays` |
| Dart files | `lower_snake_case.dart` | `policy_repository.dart` |
| Directories | `lower_snake_case` | `secure_storage/` |
| Private members | leading underscore | `_validateKey()` |
| Test files | `<subject>_test.dart` | `policy_repository_test.dart` |
| Localization keys | descriptive `lowerCamelCase` | `recoveryKeyTitle` |

| Suffix | Use |
|---|---|
| `Page` | Route-level screen |
| `Screen` | Full-screen presentation when distinct from a route page |
| `Widget` | Reusable or feature-specific UI component |
| `Controller` / `Notifier` | UI state orchestration, following the repository's chosen state-management pattern |
| `Service` | Application/domain operation with a cohesive responsibility |
| `Repository` | Domain-facing persistence contract or implementation |
| `DataSource` | Low-level storage or platform data access |
| `Exception` | Exceptional failure crossing a boundary |
| `Failure` | Typed/domain result describing an expected operation failure |

Use established project patterns consistently; do not introduce a new state-management, dependency-injection, or result convention for a single feature.

## 4. Code Style

- Follow `analysis_options.yaml` and Dart formatter output; do not suppress diagnostics without documenting an approved reason.
- Order imports: Dart SDK, Flutter SDK, third-party packages, then project imports. Separate groups with a blank line and use package imports for project code.
- Prefer `const` constructors, immutable values, small cohesive methods, explicit types at public boundaries, and exhaustive switches.
- Keep widgets focused. Separate state transitions and data access from rendering.
- Document public APIs with `///` comments when their contract is not self-evident.

Class example:

```dart
class PolicySummary {
  const PolicySummary({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}
```

Function example:

```dart
Future<Policy?> findPolicy(String policyId) async {
  if (policyId.isEmpty) {
    throw ArgumentError.value(policyId, 'policyId', 'Must not be empty');
  }
  return policyRepository.findById(policyId);
}
```

Widget example:

```dart
class PolicyCount extends StatelessWidget {
  const PolicyCount({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(l10n.policyCount(count));
  }
}
```

Error-handling example:

```dart
try {
  await policyRepository.save(policy);
} on PolicyStorageException catch (error, stackTrace) {
  logger.error(
    'Unable to save policy',
    error: error,
    stackTrace: stackTrace,
  );
  rethrow;
}
```

Log only a safe event description and redacted/approved metadata; never include the policy, user input, identifiers that reveal identity, or secret values. Convert boundary failures to typed user-facing outcomes without exposing internals.

## 5. Testing

- Use `<subject>_test.dart`; name test cases by observable behavior, e.g. `rejects tampered ciphertext`.
- Cover successful, invalid, failure, edge, and regression behavior. Use deterministic fakes and disposable temporary databases.
- Never use real client data or production secrets in tests. Ensure fixtures cannot identify a real person.
- Test transaction rollback, migration behavior, platform-specific branches, localization coverage, and audit-chain tamper detection where relevant.
- Minimum line coverage: core security 95%, database 90%, business logic 80%, UI 60%, overall 80%.
- Run `fvm dart format --output=none --set-exit-if-changed .`, `fvm flutter analyze`, and `fvm flutter test --coverage` before submitting.

## 6. Common Tasks

### Add a feature

1. Confirm its user-visible behavior and security/data-classification impact.
2. Add a cohesive module under `lib/features/<feature>/`; keep storage and platform behavior behind core interfaces.
3. Add localized strings to both ARB files and regenerate localization outputs using the configured Flutter localization workflow.
4. Add unit/widget/integration tests with synthetic data, including failure cases.
5. Update relevant documentation and `CHANGELOG.md`; run formatting, analysis, tests, and target builds.

### Add a localized string

1. Add a descriptive key and complete message to both `zh-Hant` and `en` ARB resources.
2. Use typed placeholders for dynamic values and provide placeholder metadata where required.
3. Run the configured localization generator; never hand-edit generated Dart localization files.
4. Use the generated localization API in UI code and verify both translations.

### Add a database migration

1. Follow the existing ordered migration mechanism and schema-version convention.
2. Make the migration transactional, preserve archived data and timestamps, and avoid logging row contents.
3. Add tests for a fresh database, the prior schema version, successful migration, and rollback/failure behavior.
4. Review key handling and SQLCipher configuration; never weaken encryption to simplify tests.

### Add a dependency

1. Prefer the SDK or an already-approved package. Search existing usage before adding another package.
2. Assess maintenance, licensing, platform coverage, transitive dependencies, and security implications.
3. Add the narrowest compatible version constraint, update the lockfile, and document why the dependency is needed.
4. Never add a dependency that introduces telemetry, networking, or cloud behavior without explicit product/security approval.

## 7. Do NOT

- Do not commit databases, exports, secrets, private keys, `.env`, signing files, or real user data.
- Do not use `print`, unredacted logs, analytics, HTTP/network calls, cloud APIs, or remote telemetry.
- Do not hardcode keys, passwords, salts, tokens, or recovery secrets.
- Do not implement cryptographic algorithms, change approved parameters, or downgrade authenticated encryption.
- Do not bypass secure storage, database transactions, audit logging, authorization, or input validation.
- Do not physically delete records as a shortcut for archiving or hide errors behind empty/default/success results.
- Do not hardcode UI text, update only one locale, edit generated code, or use unpinned Flutter/Dart commands.
- Do not add platform-specific behavior to shared code without an explicit abstraction and tests.
- Do not suppress analyzer errors or lower coverage requirements to conceal a defect.

## 8. Security Checklist (Before Committing)

- [ ] No PII, policy/financial data, credentials, keys, database files, exports, or secrets are staged.
- [ ] No sensitive values enter logs, errors, test output, fixtures, or screenshots.
- [ ] No network/cloud/telemetry behavior has been added.
- [ ] Key derivation, AES-256-GCM, SQLCipher, secure storage, and biometric boundaries follow approved designs.
- [ ] Encrypted input is authenticated; tampering and invalid credentials fail safely.
- [ ] Related writes are transactional; archive and timestamp behavior is correct.
- [ ] Required security actions are captured in the tamper-evident audit log without sensitive payloads.
- [ ] Both locales are complete; tests cover relevant negative and regression cases.
- [ ] `fvm flutter analyze` and relevant tests pass; security-sensitive changes received security review.

## 9. Build & Release Commands

Run from the project root with FVM. Builds require the listed platform toolchain; release signing credentials must remain local and untracked.

| Target | Build machine | Command |
|---|---|---|
| Windows desktop | Windows 11 | `fvm flutter build windows` |
| macOS desktop | macOS | `fvm flutter build macos` |
| iOS | macOS with Xcode | `fvm flutter build ios` |
| Android APK | Windows or macOS with Android SDK | `fvm flutter build apk` |
| Android App Bundle | Windows or macOS with Android SDK | `fvm flutter build appbundle` |
| Linux desktop | Linux | `fvm flutter build linux` |

Before release, run analysis and tests, verify localization and migrations, review dependency changes, validate signing and packaging on the target machine, and ensure generated artifacts and symbols are not staged.

## 10. References

- [README.md](README.md) — overview, setup, and targets
- [CONTRIBUTING.md](CONTRIBUTING.md) — branches, reviews, and testing requirements
- [SECURITY.md](SECURITY.md) — security design and vulnerability reporting
- [CHANGELOG.md](CHANGELOG.md) — release history
- [docs/](docs/) — detailed project documentation

## 11. AI Agent Specific Notes

- Read this file and the relevant source, tests, and documentation before making a change. Confirm current repository structure; the tree above describes the intended application layout and may precede implementation.
- Make focused changes and preserve established architecture. Do not create a second implementation of existing security, database, localization, or platform abstractions.
- Treat security claims as requirements, not proof that a control is already implemented. Verify the code and tests; do not claim a safeguard exists without evidence.
- Never invent cryptographic choices, parameters, threat-model decisions, retention exceptions, or security behavior. If implementation requires changing an approved security property, stop and request maintainer direction.
- Use synthetic data only. Never copy sensitive values from local files, logs, screenshots, or user material into code, tests, or responses.
- Keep both locales and all supported platforms in scope. Call out an unsupported platform behavior rather than silently omitting it.
- Do not modify generated files directly. Run the configured generator and include only the intended outputs.
- After changes, run the smallest relevant formatter, analyzer, tests, and build checks; report exact checks and any limitations honestly.
- Review the staged diff for secrets and unrelated changes. Do not commit or push unless explicitly asked.
