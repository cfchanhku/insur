# Contributing

This guide describes the expected contribution workflow for Insurance Policy Manager (`insur`). The application handles highly sensitive insurance and identity data; security and privacy requirements apply to code, tests, examples, screenshots, and review discussions.

## Branching strategy

| Branch | Purpose |
|---|---|
| `main` | Protected, reviewed production/release history |
| `develop` | Protected integration branch for the next release |
| `feature/*` | New functionality; branch from and merge into `develop` |
| `bugfix/*` | Non-urgent defect fixes; branch from and merge into `develop` |
| `hotfix/*` | Urgent production fixes; branch from `main`, then merge to both `main` and `develop` |
| `release/*` | Release stabilization from `develop`; merge the completed release to `main` and back to `develop` |

Use lowercase kebab-case descriptions and include the work item identifier when available, for example `feature/IPM-42-biometric-unlock`. Keep branches focused and short-lived. Do not push directly to protected branches.

## Commit messages

Use Conventional Commits:

```text
<type>(<scope>): <imperative summary>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `security`, `i18n`.

**Scopes:** `auth`, `db`, `crypto`, `ui`, `i18n`, `backup`, `export`, `audit`, `settings`, `clients`, `policies`, `plans`, `riders`.

Examples:

```text
feat(auth): add biometric unlock
fix(db): preserve archived policy timestamps
security(crypto): authenticate backup metadata
i18n(ui): translate recovery-key instructions
```

Use a breaking-change footer (`BREAKING CHANGE: ...`) when a change is incompatible. Never include sensitive values, client data, or secrets in commit messages.

## Pull request process

1. Branch from the correct protected base and keep the change focused.
2. Run formatting, static analysis, and the relevant tests locally.
3. Update documentation, translations, and `CHANGELOG.md` when applicable.
4. Open a pull request against `develop`, except hotfixes (target `main` and also merge the fix to `develop`).
5. Fill in the repository pull request template if one is provided. If no template exists, include the checklist below in the description.
6. Request review from the relevant code owner and a security-aware reviewer for changes touching authentication, cryptography, storage, backup, export, audit records, or data deletion.
7. Resolve review feedback and ensure required automated checks pass before merge. Squash or merge according to repository settings; do not bypass branch protection.

### Pull request checklist

- [ ] The change has a clear purpose and links to its work item, if applicable.
- [ ] No real or synthetic-but-identifiable personal data, secrets, keys, or local database files are included.
- [ ] Formatting, analysis, and relevant tests pass.
- [ ] Security, data integrity, and platform impacts have been reviewed.
- [ ] Both `zh-Hant` and `en` localization resources are updated for user-visible text.
- [ ] Documentation and changelog are updated where needed.
- [ ] Screenshots or recordings, if needed, contain no sensitive data.

### Review requirements

At least one maintainer approval and passing required CI checks are required. Security-sensitive changes also require explicit review by a reviewer familiar with the affected security design. Authors should not approve their own pull requests.

## Code review checklist

- **Correctness:** Does the change meet requirements and preserve existing behavior?
- **Security:** Are secrets protected, inputs validated, errors safe, and security controls preserved? Are cryptographic operations delegated to approved implementations?
- **Code quality:** Is the code readable, typed, cohesive, and consistent with existing patterns?
- **Testing:** Are success, failure, edge, and regression cases covered at the appropriate layer?
- **Documentation:** Are affected user, developer, and security documents accurate?
- **Internationalization:** Are all user-visible strings localized in both supported locales and do layouts handle translated text?
- **Performance:** Are database queries, cryptographic work, rendering, and large exports appropriately bounded?

## Development workflow

### Daily commands

```shell
fvm install
fvm flutter pub get
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
```

Use `fvm flutter doctor` to diagnose platform toolchain issues. Run the relevant platform build before merging platform-specific changes. Do not run Flutter or Dart through an unpinned global SDK.

### Switching between Windows and macOS

Use the same Git branch and commit history on both machines; do not synchronize working directories or private application data through Git, cloud drives, or shared archives. Commit or stash code changes before switching machines, then fetch and check out the branch on the other machine. Re-run `fvm install` and `fvm flutter pub get` on each machine. Platform-generated files and signing material must remain on their intended platform and must not be committed.

### Syncing with `develop`

Before starting or updating a feature, fetch the remote and rebase your feature branch on the current `develop` (or merge `develop` if required by repository policy). Resolve conflicts carefully, rerun formatting, analysis, and affected tests, then push using `--force-with-lease` only when rebasing a branch you own and repository policy permits it.

```shell
git fetch origin
git switch develop
git pull --ff-only origin develop
git switch feature/IPM-XX-short-description
git rebase develop
```

## Pre-commit hooks

Install a local Git hook by saving the following script as `.git/hooks/pre-commit`. On Unix, make it executable with `chmod +x .git/hooks/pre-commit`; Git for Windows runs it through Git Bash. The hook uses the repository-pinned SDK and fails the commit if a check fails.

```sh
#!/bin/sh
set -eu
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
```

Hooks run locally and are not a substitute for required CI checks or review. Keep the hook aligned with the checks required by CI.

## Testing requirements

- Add or update tests for every behavior change, including failure and boundary cases.
- Name Dart test files `<subject>_test.dart`; use descriptive test names such as `returns ... when ...`.
- Keep unit tests deterministic and isolated. Never use real client or policy information, production keys, or unredacted database fixtures.
- Test database constraints and migrations against disposable temporary databases; verify rollback behavior for failed transactions.
- Verify security-sensitive code's negative cases, including invalid authentication, tampered ciphertext, malformed recovery input, and audit-chain verification as appropriate.
- Maintain these minimum coverage targets, measured for the relevant component and overall project:

| Area | Minimum line coverage |
|---|---:|
| Core security | 95% |
| Database | 90% |
| Business logic | 80% |
| UI | 60% |
| Overall | 80% |

Coverage is evidence, not a substitute for meaningful assertions. Do not lower thresholds to make a change pass without maintainer approval.

## Documentation requirements

- Update `README.md` when setup, supported platforms, build steps, or project-level behavior changes.
- Update `AGENTS.md` when persistent architecture, security, or coding rules change.
- Update `SECURITY.md` when the security design, reporting process, supported versions, or response commitments change.
- Update relevant documents under `docs/` for architectural, data-model, operational, or user-facing behavior changes.
- Add an entry under the appropriate `CHANGELOG.md` category for user-visible or security-relevant changes.
- Write Dart API documentation comments (`///`) for public APIs and non-obvious contracts. State behavior, constraints, and security implications; avoid restating the symbol name.
- Keep examples free of real personal data, live credentials, and usable cryptographic keys.
