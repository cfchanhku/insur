# Scripts

Helper scripts for builds, packaging, and pre-commit checks. Review every
script before running it; scripts must not copy application data or expose
secrets.

## Windows release

Run from any directory in PowerShell:

```powershell
.\scripts\build-windows.ps1
```

The script builds with the repository's FVM-pinned Flutter SDK, packages the
complete Windows runner directory into `build\release`, and writes a SHA-256
sidecar. Signing is optional; install an authorized code-signing certificate
in the current user's Personal certificate store, then pass its thumbprint:

```powershell
.\scripts\build-windows.ps1 -CertificateThumbprint <thumbprint>
```

Only `insur.exe` is signed by this helper. The ZIP itself is not signed. Keep
certificates and private keys out of the repository. Without a trusted
signature, Windows may display a SmartScreen warning.

`package-windows.ps1` can package an already-built
`build\windows\x64\runner\Release` directory without rebuilding it.

macOS, iOS, Android, and Linux build scripts are not provided because their
host projects are not present in this repository.
