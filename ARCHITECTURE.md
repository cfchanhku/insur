# ARCHITECTURE.md

## Insurance Policy Manager (insur) — System Design & Module Boundaries

**Version:** 1.0.0 · **Last Updated:** 2026-10-27
**This file tells the AI agent *where code goes* and *what may not be imported*. Read it before adding new modules.**

---

## 1. System Shape

The app is a **single-process, offline, local-first Flutter application**. There is no backend, no server, no network. All persistence is local (SQLCipher), all keys live in OS secure storage.

```
┌────────────────────────────────────────────────────────────┐
│  Flutter UI (Windows / macOS / iOS / iPadOS / Android / Linux) │
│                                                            │
│  Presentation ──► Domain (Use Cases) ──► Data (Repos)      │
│       │                                     │              │
│       ▼                                     ▼              │
│  State (Riverpod)                     SQLCipher DB         │
│       │                                     │              │
│       ▼                                     ▼              │
│  Security Layer (FieldCrypto, KDF, KeyManager, RecoveryKey)│
│       │                                     │              │
│       ▼                                     ▼              │
│  Platform Abstraction                 OS Secure Storage    │
│  (Biometric, FilePicker,             (Keychain/Keystore/  │
│   SecureStorage)                       DPAPI/libsecret)    │
└────────────────────────────────────────────────────────────┘
```

**Key invariants:**
- **No network calls.** Any `http`, `dio`, `socket`, or `WebSocket` import is a bug.
- **Encryption is always applied before persistence.** Repositories encrypt PII via `FieldCrypto` before `INSERT`.
- **Keys live only in memory during a session, and in OS secure storage across sessions.** Never in the DB, never in files.
- **Audit entries are emitted from repositories, not UI.**

---

## 2. Layering (Strict, Enforced by Review)

```
┌──────────────────────────────────────────────────────────────┐
│  feature layer        lib/features/<domain>/                 │
│  (screens, widgets, notifiers, forms)                       │
├──────────────────────────────────────────────────────────────┤
│  shared layer         lib/shared/widgets/, lib/theme/,       │
│  (reusable UI, theme, l10n helpers)                          │
├──────────────────────────────────────────────────────────────┤
│  core layer           lib/core/<concern>/                    │
│  (security, database, audit, backup, logging, platform)      │
└──────────────────────────────────────────────────────────────┘
```

### Allowed imports (top → down only)

| From | May import |
|---|---|
| `features/` | `shared/`, `core/`, `providers/`, `router/`, `l10n/` |
| `shared/` | Flutter SDK, `theme/` design tokens, `l10n/` |
| `core/` | `shared/widgets/` only (rare), Dart/Flutter SDK, third-party packages |
| `providers/` | `core/`, `features/` (for types only), `router/` |
| `router/` | `features/` screens, `providers/` |

**Forbidden:**
- ❌ `core/` → `features/` (never)
- ❌ `shared/` → `core/` or `features/`
- ❌ `features/<A>/` → `features/<B>/screens/` (share via `shared/` or `providers/`)
- ❌ Any file → `main.dart` or `app.dart` (except the entrypoint itself)
- ❌ Circular imports (verified by `dart analyze`)

**If you think you need a forbidden import, the design is wrong.** Extract to `shared/` or introduce a provider.

---

## 3. Module Responsibilities

### 3.1 `core/security/` — Cryptography & Keys

| File | Responsibility | May NOT do |
|---|---|---|
| `kdf.dart` | Argon2id derivation (master key from passphrase) | Store keys, touch DB |
| `key_derivation.dart` | HKDF subkey derivation (DB/field/audit keys) | Store keys |
| `field_crypto.dart` | AES-256-GCM field encryption with AAD | Know about DB or models |
| `key_manager.dart` | Wrapped-MK lifecycle: setup, unlock, lock, biometric, change passphrase, recovery | Log secrets, format UI |
| `recovery_key.dart` | Recovery key generation, wrap/unwrap MK, rotation | Log keys, format UI |
| `pdf_encryption_service.dart` | AES-256 PDF encryption (Syncfusion) | Generate PDF content |
| `auto_lock_timer.dart` | Inactivity timer that triggers lock | Know about UI |
| `backoff_policy.dart` | Failed-attempt delays | Persist state |
| `key_exceptions.dart` | `WrongPassphraseException`, etc. | Include secrets in messages |

**Rule:** Every security module is **pure** (no UI, no DB access except `KeyManager` which uses secure storage). PII never appears in this layer.

### 3.2 `core/database/` — Persistence

| File | Responsibility |
|---|---|
| `database.dart` | `AppDatabase.open(dbKey)`, `close()`, raw access |
| `schema.dart` | Table DDL, indexes, `currentSchemaVersion` |
| `migrations.dart` | Forward-only `_migrateV<n>toV<n+1>` |
| `repositories/client_repository.dart` | CRUD + field encryption + audit |
| `repositories/policy_repository.dart` | CRUD + field encryption + audit |
| `repositories/plan_repository.dart` | CRUD + `insured_id` FK + audit |
| `repositories/rider_repository.dart` | CRUD + audit |
| `repositories/audit_repository.dart` | Append-only hash chain + purge |
| `repositories/config_repository.dart` | `app_config` key/value |

**Rules:**
- Repositories are the **only** code that touches `Database` directly.
- Every mutation (insert/update/archive/restore/delete) emits an audit entry via `AuditRepository`.
- PII fields are encrypted via `FieldCrypto` **before** `INSERT` and **decrypted after** `SELECT`.
- Repository methods return **models** (Client, Policy, Plan, Rider), never `Map<String, Object?>`.
- Raw row `Map` never leaves the repository.

### 3.3 `core/audit/` — Tamper-Evident Log

| File | Responsibility |
|---|---|
| `audit_event_type.dart` | Enum of event types (stable strings) |
| `audit_entry.dart` | Immutable entry model |
| `hash_chain.dart` | `computeEntryHash()`, `verifyChain()` |
| `audit_logger.dart` | In-memory append (delegated to `AuditRepository` in persistence) |
| `verification_result.dart` | `{isValid, brokenAt, reason, entryCount}` |

**Rules:**
- Audit metadata contains **only IDs, counts, event types** — never PII.
- Chain uses `SHA-256(prev_hash || timestamp || event_type || entity_type || entity_id || canonical_json(metadata))`.
- Timestamps normalized to UTC before hashing.
- Purge writes a `PURGE` anchor entry to continue the chain.

### 3.4 `core/backup/` — Encrypted Export/Restore

| File | Responsibility |
|---|---|
| `backup_format.dart` | Magic bytes, header layout, filename |
| `backup_header.dart` | Parse/serialize header (app version, schema, salt, nonce) |
| `backup_file.dart` | Full file: header + ciphertext + HMAC |
| `backup_crypto.dart` | Argon2id backup key, AES-256-GCM, HMAC |
| `backup_service.dart` | `createBackup()`, `restoreBackup()` (with pre-restore) |
| `backup_file_service.dart` | File picker abstraction (mockable) |

**Rules:**
- Backup passphrase is **separate** from login passphrase.
- HMAC verifies header + ciphertext before decryption (fast-fail).
- Restore requires the DB to be **closed** (contract enforced by caller).
- Restore emits `RESTORE_DB` audit entry **after** reopening (caller's responsibility).

### 3.5 `core/platform/` — Platform Abstractions

| File | Responsibility |
|---|---|
| `biometric.dart` | Wraps `local_auth` — no direct import from `features/` |
| `secure_storage.dart` | Wraps `flutter_secure_storage` |
| `file_picker.dart` | Wraps `file_picker` |

**Rule:** Any platform plugin (`local_auth`, `flutter_secure_storage`, `file_picker`, `printing`, etc.) is used **only** inside `core/platform/` or the single owning `core/` module. `features/` never imports plugins directly.

### 3.6 `features/` — Domain UI

Each feature folder has the same shape:

```
features/<domain>/
├── models/           # Domain models for this feature (usually just re-exports core models)
├── providers/        # Riverpod providers scoped to this feature
├── screens/          # Full-page screens
├── widgets/          # Reusable widgets specific to this feature
└── services/         # Optional domain services (e.g., ExportPdfService)
```

| Feature | Responsibility |
|---|---|
| `auth/` | Setup wizard, login, lock, recovery key entry, biometric enrollment |
| `clients/` | Client list, detail, form |
| `policies/` | Policy detail, form |
| `plans/` | Plan form (category → dynamic fields → riders) |
| `riders/` | Inline rider widgets (used by plans) |
| `archive/` | Archive tabs (clients / policies / plans) with restore + permanent delete |
| `settings/` | Settings screen, change passphrase dialog, regenerate recovery dialog |
| `audit/` | Audit log viewer with filters + chain verification |
| `backup/` | Backup + Restore screens |
| `export/` | Export PDF screen + `PdfExporter` + `ClientExportBundle` |
| `onboarding/` | First-launch 3-slide intro |

**Rules:**
- Screens read from providers, never from repositories directly.
- Screens call providers to mutate, never `repository.save()` directly.
- Feature widgets do not know about encryption — data arrives decrypted from providers.

### 3.7 `shared/` — Reusable UI

| Path | Responsibility |
|---|---|
| `shared/widgets/` | Generic widgets: `AppScaffold`, `EmptyState`, `LoadingIndicator`, `ErrorState`, `ConfirmDialog`, `AsyncButton`, `Skeletons`, `RecoveryKeyDialog` |
| `shared/utils/` | Pure functions (formatting, date, validation helpers) |

**Rule:** Nothing in `shared/` may depend on `core/` or `features/`.

### 3.8 `router/` — Navigation

- Single `GoRouter` instance, one per app.
- **No `redirect` logic** — navigation is driven by state changes (`Splash` reads `KeyManagerState` and navigates).
- Routes are declared in `app_router.dart`; screens are referenced via their class, never constructed inline with business logic.

### 3.9 `providers/` — Dependency Injection

- `app_providers.dart` holds the top-level providers: `keyManagerProvider`, `appDatabaseProvider`, `fieldCryptoProvider`, all `*RepositoryProvider`s, and derived `*Provider`s for lists/detail.
- Feature-specific providers live in `features/<domain>/providers/`.
- **Provider dependencies flow one direction:** `repository ← feature provider ← screen`.

---

## 4. Data Flow (The Only Allowed Direction)

```
User Action
    │
    ▼
Screen (ConsumerWidget)
    │ ref.read(<provider>.notifier).<method>()
    ▼
Feature Provider / Notifier
    │ ref.read(<repositoryProvider>.future)
    ▼
Repository
    │ encrypt PII (FieldCrypto) → SQLCipher write
    │ append audit (AuditRepository)
    ▼
SQLCipher DB
    │
    ▼
Provider invalidated → Screen rebuilds with decrypted data
```

**Never:**
- ❌ Screen → `Database` directly
- ❌ Screen → `FieldCrypto` directly
- ❌ Screen → `AuditRepository` directly
- ❌ Repository → `KeyManager` (repositories receive `FieldCrypto` as a dependency)
- ❌ Audit → `KeyManager` (audit receives only IDs)

**Exception:** `KeyManager.onAudit` callback is wired **once** in `AuditWiring.connect()`. This is the only cross-layer callback permitted.

---

## 5. Key Lifecycle (Where Keys Live)

| Key | Created in | Stored in | Used by | Lifetime |
|---|---|---|---|---|
| Master Key (MK) | `KeyManager.setup` (random 32 bytes) | Wrapped by KEK → secure storage | `KeyManager` | Session (in memory) + wrapped (at rest) |
| KEK | `Kdf.deriveMasterKey(passphrase, salt)` | **Never stored** | `KeyManager.unlock` | Ephemeral (transient) |
| DB Key | `SubKeyDeriver.deriveDbKey(MK)` | **Never stored** | `AppDatabase.open` | Session |
| Field Key | `SubKeyDeriver.deriveFieldKey(MK)` | **Never stored** | `FieldCrypto` | Session |
| Audit Key | `SubKeyDeriver.deriveAuditKey(MK)` | **Never stored** | `AuditRepository` | Session |
| Recovery Wrapped MK | `RecoveryKey.setupRecoveryKey` | Secure storage (separate key) | `RecoveryKey` login | Persistent |
| Backup Key | `BackupCrypto.deriveBackupKey(backupPassphrase, salt)` | **Never stored** | BackupService | Per-operation |
| Biometric Key | `KeyManager.enableBiometricUnlock` (random) | Secure storage | `KeyManager.unlockWithBiometric` | Persistent |

**Rules:**
- Sub-keys (DB, Field, Audit) are **never persisted** — they re-derive from MK on every unlock.
- MK is **wrapped by KEK** at rest (post-Prompt R wrapped-MK model).
- Any key material in memory is zeroed via `_zero(Uint8List)` on lock/logout.

---

## 6. Encryption Boundaries

| Data | SQLCipher (whole DB) | FieldCrypto (per-field) | PDF Password | Backup |
|---|---|---|---|---|
| Client name, DOB, phone, email, address | ✅ | ✅ | — | ✅ |
| Policy no, notes, coverage | ✅ | ✅ | — | ✅ |
| Plan coverage, notes, deductible | ✅ | ✅ | — | ✅ |
| Rider coverage, deductible | ✅ | ✅ | — | ✅ |
| IDs, timestamps, enums | ✅ | ❌ (queryable) | — | ✅ |
| Audit metadata | ✅ | ❌ (already ID-only) | — | ✅ |
| Backup file | — | — | — | ✅ (AES-256-GCM + HMAC) |
| Exported PDF | — | — | ✅ (AES-256) | — |

**Rule:** Any new PII field must be added to **both** the SQLCipher schema AND the FieldCrypto boundary. Adding a raw `TEXT` column without FieldCrypto is a bug.

---

## 7. PDF Export Module (Cross-Cutting)

The exporter is the **only** feature that reads across all repositories:

```
ExportPdfScreen
  → collects selected clients
  → for each client: repositories fetch policies, plans, riders
  → resolves insured names via clientByIdProvider
  → builds ClientExportBundle (with insuredNamesById)
  → PdfExporter.exportBundles(...)  → produces raw PDF bytes
  → PdfEncryptionService.encrypt(...) → produces encrypted PDF
  → writes file
  → emits EXPORT_PDF audit
```

**Rules:**
- `PdfExporter` produces **searchable text** (no rasterized text).
- Layout follows `Ref-Form-20260914` — the "受保人 / Insured" row appears **per plan section**, not in the header.
- Bundles are data-only; no provider references inside `PdfExporter`.
- Encryption happens **after** layout generation (never inside layout code).

---

## 8. Error Handling Boundaries

| Layer | Behavior |
|---|---|
| Repository | Throws `DatabaseException` (wrapped) — never leaks raw SQL errors to UI |
| Service (backup, export, security) | Throws domain exception (`BackupException`, `PdfEncryptionException`, `WrongPassphraseException`) — **no PII**, **no secrets** in messages |
| Notifier | Catches, sets `AsyncValue.error(...)` — UI shows friendly message |
| Screen | Reads `AsyncValue.when` — shows `ErrorState` with retry |

**Rule:** Error messages are user-facing. They must never contain:
- Raw SQL
- File paths with user home directory
- Any PII or key material

---

## 9. What Not to Do (Agent Traps)

These are the mistakes most likely to be made by an AI agent working on this project:

1. **Don't add a `Database` parameter to a widget.** Widgets use providers.
2. **Don't call `FieldCrypto` from a form.** Encrypt happens in the repository.
3. **Don't log from the security layer.** Keys and PII never reach the logger.
4. **Don't add a new PII field without a migration + FieldCrypto wrap + ARB key + audit consideration.**
5. **Don't put `print()` in `core/`.** Use `Logger` from `core/logging/`.
6. **Don't add `http`, `dio`, or any network package.** This app is offline by design.
7. **Don't rasterize text in the PDF.** Use `pw.Text`, not `pw.Image`.
8. **Don't hardcode `Color(...)` in a widget.** Use `Theme.of(context).colorScheme`.
9. **Don't add a new locale without both ARB files.**
10. **Don't put business logic in `shared/`.** `shared/` is only reusable widgets and pure functions.
11. **Don't import a plugin from `features/`.** Plugins live in `core/platform/`.
12. **Don't bypass the repository to "just query for this one screen."** Add a repository method.
13. **Don't add a provider in a screen file.** Providers live in `providers/` or `features/<domain>/providers/`.
14. **Don't modify a released migration.** Add a new one.
15. **Don't touch the layout of `PdfExporter` without re-verifying that the PDF is still searchable.**

---

## 10. New Feature Decision Tree

When asked to add a feature, ask:

1. **Does it need new data?**
   - Yes → new model + migration + repository + field encryption (if PII) + tests.
2. **Does it mutate data?**
   - Yes → must go through repository → must emit audit entry.
3. **Does it touch keys or crypto?**
   - Yes → goes in `core/security/` with known-vector tests.
4. **Does it touch files or OS?**
   - Yes → goes in `core/platform/` or a service in `features/`.
5. **Does it appear in the PDF?**
   - Yes → update `PdfExporter` + `ClientExportBundle` + searchable test.
6. **Does it have user-facing text?**
   - Yes → both ARB files + `flutter gen-l10n`.
7. **Does it need UI state?**
   - Yes → new provider in `features/<domain>/providers/` or `providers/`.

---

**End of ARCHITECTURE.md**