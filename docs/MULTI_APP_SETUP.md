# Multi-App Development Setup

This guide describes a future arrangement for developing multiple Flutter applications on the same workstation while keeping each app's source, configuration, secrets, and build artifacts isolated. The shared host is a convenience, not a data-sharing boundary for application data.

## Directory structure

Example for a Unix-like home directory:

```text
~/apps/
├── insur/
│   ├── .fvmrc
│   ├── .env                 # Local-only; ignored by Git
│   ├── .envrc               # Optional, non-secret environment selection
│   ├── secrets/             # Local-only restricted credentials, if approved
│   └── symbols/             # Local restricted staging; archive offline
├── another-app/
│   └── ...
├── shared/
│   ├── scripts/             # Reviewed generic tooling only
│   └── templates/           # Non-secret templates
└── secure-offline-storage/
    ├── insur/
    │   └── symbols/
    └── another-app/
        └── symbols/
```

On Windows, use a corresponding user-owned directory such as `%USERPROFILE%\apps\`; do not assume Unix home paths or permissions. Do not put repositories inside cloud-synchronized folders.

## Isolation matrix

| Resource | Share across apps? | Rule |
|---|---|---|
| Android SDK/toolchain | Yes | Shared installation is acceptable; pin each project's target and build tools |
| FVM-managed Flutter SDK versions | Yes | SDK installations may be shared, but each repository's `.fvmrc` is independent |
| Pub package cache | Yes | Cache is a performance optimization; never put credentials or private user data in it |
| Git binary and editor | Yes | Tool installation can be shared; workspace config remains project-specific |
| App source and Git remotes | No | Separate repository, branches, access controls, and release history |
| `.fvmrc` | No | Each app pins its own compatible Flutter SDK |
| `.env` / `.envrc` | No | Per-app local config; secrets must not be committed or shared broadly |
| `secrets/` and signing identities | No | App-specific, access-restricted, encrypted storage and least privilege |
| Symbols and obfuscation maps | No | Store by app/version/build in restricted offline storage |
| Databases, backups, exports, fixtures | No | Never share between apps; test data is synthetic and app-scoped |
| CI credentials and signing keys | No | Separate project-scoped secret ownership and rotation |

## Per-app configuration

- **`.fvmrc`:** commit the selected Flutter version to that app's repository. Install it using FVM when entering the repository.
- **`.env`:** create locally from the app's documented example. Confirm Git ignores it; never place passwords, encryption keys, recovery keys, PII, or signing credentials in it.
- **`.envrc`:** optional direnv configuration for non-secret app-specific environment selection. Review before allowing it; do not automatically trust a new repository's environment file.
- **`secrets/`:** avoid local secret files where OS keychain/credential stores or an approved manager are available. If unavoidable, restrict permissions, encrypt at rest, exclude it from Git, cloud sync, backups, logs, and screenshots.
- **`symbols/`:** use only as a restricted temporary staging directory if allowed by policy. Final symbol archives belong in separately controlled offline/encrypted storage; never commit this directory.

## Shared resources

Android SDKs, Pub cache, FVM version installations, Git, and editor binaries may be shared to reduce disk use. Shared caches must never be treated as authoritative source or as a location for credentials or app data. Do not point multiple applications at the same signing configuration or output directory.

## Workflow examples

### Switch between projects

```shell
cd ~/apps/insur
fvm install
fvm flutter --version
fvm flutter pub get
```

Then change directories to another app and repeat. Do not carry one project's environment variables or secrets into another project's shell.

### Add a new Flutter app

1. Create a separate repository and apply its own access and branch protections.
2. Choose and commit that app's `.fvmrc`.
3. Add its own `.env.example` with non-secret names/defaults; ignore the local `.env`.
4. Keep signing material, symbols, and any app-specific local data in isolated protected locations.
5. Confirm shared SDK/cache paths do not contain private data.
6. Build and test from that app's root; verify outputs do not collide with another project's artifacts.

## Checklist

- [ ] Each app has a distinct source repository and remote.
- [ ] Each repository pins its own Flutter SDK in `.fvmrc`.
- [ ] Local environment files and secrets are ignored and not cloud-synchronized.
- [ ] Shared tool caches contain no credentials, user databases, or exports.
- [ ] Signing assets, symbols, and release outputs are app- and version-specific.
- [ ] Application data is never moved through developer folders or source control.
- [ ] Per-app dependency, vulnerability, release, and retention reviews remain independent.
