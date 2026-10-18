# Insurance Policy Manager — Implementation Plan

| Document version | 3.1 |
|---|---|
| Date | 2026-10-19 |
| Classification | Proprietary — Internal Use Only |
| Product | Insurance Policy Manager (`insur`) |
| Status | Planning baseline; estimates and platform decisions require confirmation at phase gates |

> This plan defines the intended product and delivery approach. Security algorithms and platform requirements stated here are design constraints, not a claim that controls have already been implemented or independently certified. Resolve open decisions through documented review before implementation.

## Table of contents

1. [Revised Development Environment](#part-1-revised-development-environment)
2. [Machine-Specific Setup](#part-2-machine-specific-setup)
3. [Development Workflow](#part-3-development-workflow)
4. [Repository and Branching](#part-4-repository--branching)
5. [Build and Release Matrix](#part-5-build--release-matrix)
6. [Implementation Plan](#part-6-implementation-plan)
7. [Risks and Mitigations](#part-7-risks--mitigations)
8. [Summary](#part-8-summary)
9. [Next Steps](#part-9-next-steps)
10. [Companion Documents to Update](#part-10-companion-documents-to-update)

## Part 1: Revised Development Environment

### Confirmed setup

| Environment | Responsibility | Data boundary |
|---|---|---|
| Windows 11 workstation | Primary development, source editing, tests, and Windows desktop builds; Android builds are optional when Android tooling is installed | Source and synthetic test data only |
| macOS workstation | macOS/iOS builds, simulator/device validation, Apple signing, and notarization where applicable; Android builds are optional | Source and synthetic test data only; signing material remains local and protected |
| GitHub | Private code repository, pull requests, and source-code collaboration only | **Code only**; never application data, databases, exports, keys, credentials, or user backups |

### Access model

```text
 Windows 11 workstation                         macOS workstation
 ┌──────────────────────────┐                   ┌──────────────────────────┐
 │ Primary development      │                   │ Apple platform builds    │
 │ Windows desktop builds  │                   │ iOS + macOS builds       │
 │ Optional Android builds │                   │ Optional Android builds │
 └─────────────┬────────────┘                   └────────────┬─────────────┘
               │ SSH: source code only                      │ SSH: source code only
               └──────────────────┐       ┌───────────────────┘
                                  ▼       ▼
                         ┌────────────────────┐
                         │ Private GitHub repo│
                         │ Code / PRs only    │
                         └────────────────────┘

 User's encrypted local data remains on the user's device and is never synced
 through the development workstations or GitHub.
```

### Division of responsibilities

| Activity | Windows 11 | macOS | GitHub |
|---|---|---|---|
| Primary Dart/Flutter coding | Primary | Supported | No execution |
| Windows desktop compilation | Required | Not supported | No execution |
| macOS desktop compilation | Not supported | Required | No execution |
| iOS simulator, signing, archive | Not supported | Required | No signing secrets |
| Android build | Optional | Optional | No signing secrets |
| Source history and review | Git client | Git client | Canonical remote |
| Real user data storage | Not for development | Not for development | Prohibited |

### Platform support matrix

| Target | Build machine | Runtime target | Release artifact |
|---|---|---|---|
| Windows desktop | Windows 11 | Windows 10/11 versions validated by release testing | Signed Windows package/installer, format to be selected |
| macOS desktop | macOS | Supported macOS versions set at release gate | Signed and notarized app/disk image as applicable |
| iOS | macOS with Xcode | Supported iOS versions set at release gate | Signed IPA/App Store Connect archive |
| Android | Windows or macOS with Android SDK | Supported Android API range set at release gate | APK for direct testing; AAB for Play distribution |
| Linux desktop | Linux | Distribution/runtime requirements set at release gate | AppImage/deb/rpm or other selected package |

Apple builds require macOS. Linux is a planned target; its build agent and packaging process must be provisioned and validated before a Linux release is promised. No single machine is assumed to produce all target builds.

## Part 2: Machine-Specific Setup

Install tools from their official sources and keep SDK versions reproducible. Follow [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) for detailed commands.

### Windows 11

| Tool | Requirement / purpose |
|---|---|
| Git for Windows | Source control and SSH client |
| Flutter SDK through FVM | Project Flutter version, pinned by repository `.fvmrc` |
| Visual Studio 2022 | Desktop development with C++ workload and Windows SDK for Windows desktop builds |
| VS Code | Flutter/Dart extensions; optional editor |
| FVM | Select the repository-pinned Flutter SDK |
| OpenSSL | Only the native development/build dependency required by the selected SQLCipher integration; confirm version and provenance before use |
| GitHub SSH | Per-user SSH key registered with GitHub; private key remains in Windows credential storage |
| Android SDK (optional) | Android command-line tools, platform, and build tools for Android targets |

### macOS

| Tool | Requirement / purpose |
|---|---|
| Xcode 26 | iOS and macOS toolchain, simulator, signing, and Apple platform SDKs |
| Xcode command-line tools | Compiler and build utilities |
| Homebrew | Optional package manager for developer tools |
| Flutter SDK through FVM | Project Flutter version |
| CocoaPods | iOS/macOS plugin dependency integration when required by Flutter plugins |
| VS Code | Flutter/Dart extensions; optional editor |
| GitHub SSH | Per-user SSH key registered with GitHub; private key remains in macOS Keychain |
| Apple Developer account | Required for device signing and distribution; managed by authorized release personnel |
| Android SDK (optional) | Android builds if desired |

Never put signing credentials, provisioning profiles, private keys, SQLCipher keys, or recovery keys in the repository or shared cloud storage.

## Part 3: Development Workflow

### Standard workflow

```text
Issue / approved task
        │
        ▼
Branch from develop ──► implement + localized strings + tests
        │                           │
        │                           ▼
        │               format / analyze / test / platform check
        │                           │
        └───────────────────────────▼
                         Pull request → review + CI
                                        │
                                        ▼
                              merge into develop
                                        │
                           release stabilization branch
                                        │
                                        ▼
                         signed, tested release → main
```

### Release workflow

1. Cut `release/<version>` from `develop` after feature freeze.
2. Lock scope to release fixes, translation corrections, and release documentation.
3. Run the release checklist and security review for security-sensitive changes.
4. Build each target on its supported machine; verify signing, package contents, version, and recovery/backup flows.
5. Tag the approved release and merge the release branch to `main`; merge release fixes back to `develop`.
6. Publish through approved distribution channels. Archive build provenance and symbols in restricted offline storage.

### Sync protocol

- GitHub is the canonical source-code remote; pull requests are the integration path.
- Commit or stash source changes before changing machines; fetch the branch on the other machine and verify the commit hash.
- Re-run `fvm install`, dependency resolution, formatter, analyzer, and applicable tests on each workstation.
- Keep generated build output and platform-specific signing state out of Git.
- Merge or rebase `develop` according to repository policy; never force-push protected branches.

**Never-copy rule:** never copy or sync application databases, user backups, exports, plaintext data, recovery keys, signing identities, private keys, `.env` contents, or secrets between workstations or through GitHub/cloud drives. Source code only. For actual user data, use the application's approved encrypted backup and recovery workflow, not developer file transfer.

## Part 4: Repository & Branching

### Intended repository structure

```text
.
├── android/ ios/ macos/ windows/ linux/   # Flutter host projects (as enabled)
├── assets/                                # Bundled non-sensitive assets
├── docs/                                  # Product, setup, design, and build docs
├── integration_test/                      # Integration tests
├── lib/
│   ├── core/                              # Security, database, audit, platform
│   ├── features/                          # Auth, clients, policies, plans, etc.
│   ├── l10n/                              # Localization resources/generated code
│   └── shared/                            # Reusable UI and utilities
├── test/                                  # Unit and widget tests
├── .fvmrc
├── pubspec.yaml
└── README.md
```

This is the target layout. Only commit platform directories and generated files that are intentionally part of the Flutter project.

### Branching strategy

| Branch | Policy |
|---|---|
| `main` | Protected release history; no direct pushes |
| `develop` | Protected integration branch; no direct pushes |
| `feature/*` | New work, typically based on `develop` |
| `bugfix/*` | Non-urgent fixes, typically based on `develop` |
| `hotfix/*` | Urgent release fixes from `main`; merge fix into `develop` too |
| `release/*` | Stabilization branch from `develop`; merge/tag release to `main` |

Name work branches `feature/IPM-XX-short-description` (or the corresponding `bugfix/`, `hotfix/`, `release/` prefix), with lowercase kebab-case description.

### Commit convention

Use Conventional Commits: `<type>(<scope>): <imperative summary>`.

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `security`, `i18n`.
- Scopes: `auth`, `db`, `crypto`, `ui`, `i18n`, `backup`, `export`, `audit`, `settings`, `clients`, `policies`, `plans`, `riders`.
- Do not include user data, secrets, or credentials in commit metadata.

## Part 5: Build & Release Matrix

| Target | Build machine | Command |
|---|---|---|
| Windows desktop | Windows 11 | `fvm flutter build windows --release` |
| macOS desktop | macOS | `fvm flutter build macos --release` |
| iOS | macOS + Xcode | `fvm flutter build ipa --release` |
| Android APK | Windows or macOS + Android SDK | `fvm flutter build apk --release` |
| Android App Bundle | Windows or macOS + Android SDK | `fvm flutter build appbundle --release` |
| Linux desktop | Linux | `fvm flutter build linux --release` |

### Symbols management

Treat debug symbols and mapping files as sensitive operational artifacts: they can expose source structure and may help reverse engineering. Generate symbols for releases when supported, store them outside the repository in access-controlled, encrypted, offline or approved restricted storage, and associate them with exact version/build identifiers. Never commit `symbols/`, obfuscation maps, dSYMs, PDBs, signing assets, or user data. Document retrieval and retention owners before first production release.

## Part 6: Implementation Plan

### Phases and exit criteria

| Phase | Scope | Exit criteria |
|---|---|---|
| 0 — Discovery | Confirm source form/data model, requirements, threat model, supported OS baselines, data lifecycle, legal/privacy constraints, and unresolved product decisions | Approved scope, data dictionary, threat model, architecture decisions, and acceptance criteria |
| 1 — Environment | Provision Windows/macOS toolchains, FVM pin, repository CI, code review rules, and reproducible test/build commands | Both machines pass pinned SDK checks; CI validates format/analyze/tests; access boundaries documented |
| 2 — Foundation | Flutter shell, navigation, theme, localization scaffolding, error boundaries, logging redaction, dependency policy, test harness | App starts on target development platforms; both locales load; no sensitive logging path |
| 3 — Security Core | Key hierarchy, Argon2id integration, secure storage, AES-256-GCM, SQLCipher integration, authentication, recovery key, audit chain | Independent security design review; adversarial tests for invalid keys/tampering; platform storage tests |
| 4 — Data Management | Client/policy/plan/rider model and CRUD, validation, archive, search, migrations, transactional repositories | Data integrity tests, migration/rollback coverage, full workflows with synthetic fixtures |
| 5 — Backup/Restore/Export | Encrypted backup, restore validation, password-protected PDF/export policy, file handling and audit events | Restore drills; corruption/wrong-key tests; exported files are protected and warnings are clear |
| 6 — i18n & Polish | Complete English and Traditional Chinese copy, accessibility, responsive layouts, usability refinement | Locale parity, text expansion/accessibility checks, user review with synthetic data |
| 7 — Platform Builds | Windows, macOS, iOS, Android and Linux packaging; platform secure storage and file APIs; signing workflows | Release-mode builds on designated machines and platform acceptance tests |
| 8 — Security Testing | Threat-led test plan, dependency review, static checks, penetration review, recovery/backup abuse cases | Findings triaged; blockers remediated; security sign-off and evidence retained |
| 9 — Release | Versioning, release notes, signing, notarization/store submission, support and incident procedures | Approved candidate, verified backups/recovery, tested distribution packages, release authorization |

### Timeline summary

Indicative schedule: **approximately 20–22 weeks** for a small, experienced team, subject to discovery and platform integration risk. Phases may overlap only when their dependencies and security review gates permit it.

| Approximate weeks | Phases |
|---|---|
| 1–2 | 0 Discovery |
| 2–3 | 1 Environment |
| 3–5 | 2 Foundation |
| 5–9 | 3 Security Core |
| 8–12 | 4 Data Management |
| 11–14 | 5 Backup/Restore/Export |
| 12–16 | 6 i18n & Polish |
| 15–18 | 7 Platform Builds |
| 17–20 | 8 Security Testing |
| 20–22 | 9 Release and contingency |

Estimates are planning ranges, not commitments. Security findings, native plugin issues, product decisions, and Apple review may extend the schedule.

### Resource plan

Minimum planning assumption: one Flutter/Dart lead, one additional application engineer, a security/cryptography reviewer, a QA/test engineer, a bilingual Traditional Chinese/English product reviewer, and a release owner. Roles may be shared but security review and release approval should be independent of the author where practical.

| Capability | Primary contribution |
|---|---|
| Product/domain owner | Resolve policy workflow, data definitions, retention, acceptance criteria |
| Flutter engineers | App foundation, features, database integration, cross-platform UI |
| Security reviewer | Threat model, key management, crypto integration, audit and release review |
| QA engineer | Test strategy, migration/restore drills, device/platform acceptance |
| Bilingual reviewer | Terminology, translation quality, locale-specific usability |
| Release owner | Signing, symbols, packaging, provenance, distribution and rollback |

## Part 7: Risks & Mitigations

| Risk | Impact | Mitigation / owner |
|---|---|---|
| Incorrect cryptographic composition or key lifecycle | Critical confidentiality/integrity failure | Adopt reviewed design, established libraries, independent security review, negative tests; security reviewer |
| Recovery key lost or exposed | Permanent data loss or compromise | Define one-time recovery ceremony, clear user guidance, never escrow; test backup/recovery with synthetic data; product/security |
| SQLCipher native integration differs by platform | Data exposure, build failure, migration risk | Prototype early on all target systems; verify encryption at rest and fail-closed behavior; platform lead |
| Cross-platform secure storage inconsistency | Platform-specific key disclosure or lockout | Capability abstraction, per-platform security review, explicit supported OS matrix; security/platform |
| Workstation/cloud data leakage | Confidentiality breach | Source-only GitHub, `.gitignore`, staging checks, no real data in development; all contributors |
| Data migration or restore corruption | User data loss | Transactional versioned migrations, atomic restore, pre-restore validation, tested recovery and backups; data/QA |
| Bilingual or layout regression | Incorrect workflow or inaccessible controls | Locale parity checks, expanded text testing, bilingual review; UX/product |
| Native signing credentials mishandled | Unauthorized releases | Least privilege, local secure storage, no repository secrets, release approval and audit; release owner |
| Schedule compression bypasses security gates | Undetected high-impact flaws | Phase exit criteria are non-waivable without documented risk acceptance; sponsor |
| Third-party package vulnerability or abandonment | Supply-chain compromise / platform breakage | Minimize dependencies, pin constraints, monitor advisories, review transitive dependencies; engineering/security |
| Platform-specific behavior not tested | Failures after distribution | Build and test on designated target machines and real supported devices; QA/release |
| Audit chain mistaken for tamper-proof storage | False assurance | Document threat limits, protect keys, verify chain, retain independent backups where policy permits; security reviewer |

## Part 8: Summary

| Decision area | Baseline |
|---|---|
| Development | Windows 11 is primary; macOS owns Apple platform builds |
| Source hosting | GitHub stores source code only |
| Data model | Fully local sensitive client/policy/plan/rider data |
| Security | SQLCipher AES-256, Argon2id, AES-256-GCM, secure storage, recovery key, tamper-evident two-year audit log |
| Localization | Traditional Chinese (`zh-Hant`) and English (`en`) |
| Branch integration | Feature work through protected `develop`; releases through protected `main` |
| Delivery estimate | Approximately 20–22 weeks, subject to phase-gate decisions and risk |
| Release gate | Platform builds, data recovery validation, security review, and authorized signing |

## Part 9: Next Steps

1. Confirm product owner, security reviewer, release owner, and private vulnerability contact.
2. Approve the threat model, key hierarchy, crypto parameters, recovery flow, audit retention semantics, and data deletion/archival policy.
3. Confirm minimum supported OS versions and distribution channels for every platform, including whether Linux is in the initial release.
4. Validate the existing data model and source form; approve field-level sensitivity and required/optional fields.
5. Provision Windows and macOS development machines and verify the pinned Flutter toolchain.
6. Prototype SQLCipher, secure storage, biometric access, encrypted backup, and recovery on target platforms before full feature work.
7. Establish protected branches, CI, dependency review, test coverage reporting, and release artifact/symbol storage.

## Part 10: Companion Documents to Update

Keep these documents aligned with approved decisions and implementation:

- [README.md](../README.md) — project overview and quick start.
- [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) — machine provisioning and daily workflow.
- [BUILD_MATRIX.md](BUILD_MATRIX.md) — supported builders, packages, output paths, distribution.
- [WIREFRAMES.md](WIREFRAMES.md) — bilingual screen behavior and design handoff.
- [MULTI_APP_SETUP.md](MULTI_APP_SETUP.md) — workstation isolation guidance.
- [AGENTS.md](../AGENTS.md) — persistent implementation and security rules.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — branch, testing, review, and release contribution workflow.
- [SECURITY.md](../SECURITY.md) — current security design, reporting contact, and supported releases.
- [CHANGELOG.md](../CHANGELOG.md) — user-visible and security-relevant changes.
