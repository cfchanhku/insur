# Audit

The current implementation provides an in-memory SHA-256 hash-chained audit
log with chain verification. SQLCipher persistence, two-year retention, and
daily purge are planned for Phase 4; they are not implemented by the in-memory
logger. An unkeyed hash chain detects changes relative to a trusted chain head,
but does not prevent an attacker who can rewrite the entire log from
recomputing every hash. Persistence and independent integrity anchoring require
security review before production use.
