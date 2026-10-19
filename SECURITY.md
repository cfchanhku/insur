# Security Policy

Insurance Policy Manager (`insur`) is intended to manage highly sensitive personal, financial, and insurance information. Security reports must be handled privately.

## Supported versions

| Version | Security support |
|---|---|
| `0.1.x` | Supported during initial development; report vulnerabilities privately |

Only the latest supported release line receives security fixes. Unsupported or unreleased builds may not receive fixes. Update this table as release lines are published.

## Reporting a vulnerability

**Do not open a public issue, pull request, discussion, or disclosure containing vulnerability details.** Report suspected vulnerabilities through the project's private security email channel:

**Private security email:** `[Project maintainer: replace with an active private security contact before publishing this policy]`

The address is intentionally left for the repository owner to configure; do not send vulnerability details to a guessed or unverified address. If no private contact is configured, contact a project maintainer privately through an already-established trusted channel and ask for a secure reporting address.

Please include, where possible:

- A clear description and affected version, platform, and component.
- Reproduction steps or a minimal proof of concept that does not expose real user data.
- Potential impact, prerequisites, and affected confidentiality, integrity, or availability.
- A suggested mitigation or fix, if known.

Do not include real client records, production databases, passwords, private keys, recovery keys, or other people's data in a report. Coordinate disclosure with maintainers and allow a fix to be prepared before public disclosure.

## Response timeline

- **Acknowledgment:** within 48 hours.
- **Initial triage:** within 5 days.
- **Target remediation:** within 30 days for critical issues and 90 days for other confirmed issues.

These are response targets, not a guarantee; complexity, upstream dependencies, and release coordination may affect remediation. Maintainers should communicate material changes in status privately.

## Scope

### In scope

- The application and its local storage, including SQLCipher configuration and database handling.
- Cryptographic key derivation, encryption, recovery, and key lifecycle.
- Authentication and biometric integration.
- Encrypted backup and restore.
- Data export and handling of exported files.
- Audit log integrity, retention, and verification.

### Out of scope

- Social engineering or attacks requiring physical access to an unlocked or compromised device.
- Vulnerabilities in third-party services outside the application's control.
- Issues in upstream operating systems, SDKs, or dependencies that are not caused by this project's integration (please report them to the appropriate maintainers as well).
- Generic security advice, unsupported-version-only issues, and findings without a reproducible security impact.

If uncertain whether a report is in scope, report it privately and explain the scenario.

## Security design summary

The intended design is local-first: application data is not uploaded to GitHub or another cloud service. GitHub stores source code only.

- **Password-based key derivation:** Argon2id.
- **Authenticated encryption:** AES-256-GCM for protected data and backups.
- **Field-level encryption:** The `FieldCrypto` primitive encrypts values with
  AES-256-GCM and binds ciphertext to its entity, field, and record through AAD.
  Its stored value is base64 of nonce, ciphertext, and tag. The primitive is not
  yet integrated with client or policy persistence; callers remain responsible
  for key lifecycle and supplying matching AAD. Its secure-random 96-bit nonces
  make collisions extremely unlikely, but cannot guarantee absolute uniqueness.
- **Key management:** The MVP stores the passphrase-derived master key
  directly in `FlutterSecureStorage`, separately from its Argon2id salt, and
  derives database, field, and audit subkeys in memory. The KeyManager and
  inactivity timer are not yet integrated with the application UI. Wrapping
  the master key with a separate key-encryption key is deferred.
- **Database encryption:** SQLCipher using AES-256.
- **Hashing and integrity:** SHA-256/SHA-512 for approved integrity and hash-chain uses; hashes are not substitutes for password hashing or authenticated encryption.
- **Key hierarchy:** user authentication material derives or unlocks a protected key-encryption key using Argon2id; that key protects randomly generated data-encryption keys, which encrypt database and backup data. Keys must be separated by purpose, never hardcoded, and kept in approved platform secure storage where applicable. Exact parameters and lifecycle must follow the reviewed implementation and must not be inferred from this summary.
- **Recovery key:** an offline recovery mechanism intended to restore access without cloud escrow. It must be generated and handled securely and must not be stored with encrypted backups.
- **Audit log:** a tamper-evident, hash-chained record of relevant events with two-year retention; sensitive payloads are excluded.

This section describes the security design requirements and is not a certification that every control is implemented or independently audited. Consult the implementation and tests before relying on a specific control.

## Data classification

PII, financial data, policy numbers, client and insured-person details, authentication material, database files, backups, and exports are **HIGH or CRITICAL sensitivity**. Handle them accordingly:

- Do not put them in source control, issues, logs, test fixtures, or screenshots.
- Encrypt stored data and protect keys separately.
- Use synthetic test data and secure deletion/retention procedures where required.

## Safe harbor

We welcome good-faith security research conducted to identify and responsibly report vulnerabilities. Researchers should avoid privacy violations, service disruption, data exfiltration, persistence, and access to data that is not theirs; stop testing and report privately if sensitive data is encountered. We will make reasonable efforts not to pursue legal action for security research that follows this policy and is conducted in good faith. This statement does not authorize unlawful access or override applicable law.
