# Encrypted backup and restore

`BackupService` writes the closed, checkpointed SQLCipher database file as a
single opaque AES-256-GCM payload. A separate Argon2id passphrase protects each
backup; the passphrase is not stored. The fixed plaintext header is included
as GCM associated data and is authenticated again by a domain-separated
HMAC-SHA256.

Callers must stop database writes, checkpoint SQLCipher, and close the database
before creating or restoring a backup. Restore verifies the backup and makes a
pre-restore backup before atomically replacing the database file. It does not
open or migrate the restored database. The caller must reopen it to run schema
migrations; if that fails, restore the pre-restore backup.

Since the database is closed during file operations, call
`recordBackupAudit` or `recordRestoreAudit` after reopening it. No database or
backup contents are included in audit metadata.
