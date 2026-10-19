/// Defines versioned tables and indexes for the encrypted application database.
///
/// PII fields use TEXT because FieldCrypto stores base64-encoded authenticated
/// ciphertext. Coverage amounts also use TEXT because they are encrypted and
/// numeric operations must occur only after decryption. Low-cardinality fields
/// such as role, gender, status, and category remain unencrypted for querying.
library;

/// SQL names and initial schema statements.
class Schema {
  const Schema._();

  /// Client table.
  static const String clients = 'clients';

  /// Policy table.
  static const String policies = 'policies';

  /// Plan table.
  static const String plans = 'plans';

  /// Rider table.
  static const String riders = 'riders';

  /// Audit events table.
  static const String auditLog = 'audit_log';

  /// Migration history table.
  static const String schemaVersion = 'schema_version';

  /// Application configuration table.
  static const String appConfig = 'app_config';

  /// Generic row identifier.
  static const String id = 'id';

  /// Client role field.
  static const String role = 'role';

  /// Client name field.
  static const String name = 'name';

  /// Client gender field.
  static const String gender = 'gender';

  /// Client date-of-birth field.
  static const String dob = 'dob';

  /// Client phone field.
  static const String phone = 'phone';

  /// Client email field.
  static const String email = 'email';

  /// Free-form notes field.
  static const String notes = 'notes';

  /// Creation timestamp field.
  static const String createdAt = 'created_at';

  /// Last update timestamp field.
  static const String updatedAt = 'updated_at';

  /// Archive timestamp field.
  static const String archivedAt = 'archived_at';

  /// Foreign key to the owning client.
  static const String clientId = 'client_id';

  /// Insurer-assigned policy number.
  static const String policyNo = 'policy_no';

  /// Insurance company name.
  static const String company = 'company';

  /// Policy effective date.
  static const String effectiveDate = 'effective_date';

  /// First premium date.
  static const String firstPremiumDate = 'first_premium_date';

  /// Currency code.
  static const String currency = 'currency';

  /// Policy status.
  static const String status = 'status';

  /// Foreign key to the owning policy.
  static const String policyId = 'policy_id';

  /// Plan category.
  static const String category = 'category';

  /// Plan display name.
  static const String planName = 'plan_name';

  /// Encrypted coverage amount.
  static const String coverageAmount = 'coverage_amount';

  /// Payment term.
  static const String paymentTerm = 'payment_term';

  /// Coverage period.
  static const String coveragePeriod = 'coverage_period';

  /// Foreign key to the owning plan.
  static const String planId = 'plan_id';

  /// Rider display name.
  static const String riderName = 'rider_name';

  /// Deductible.
  static const String deductible = 'deductible';

  /// Waiting period.
  static const String waitingPeriod = 'waiting_period';

  /// Audit timestamp.
  static const String timestamp = 'timestamp';

  /// Audit event type.
  static const String eventType = 'event_type';

  /// Serialized audit metadata.
  static const String metadata = 'metadata';

  /// Previous audit hash.
  static const String prevHash = 'prev_hash';

  /// Current audit hash.
  static const String entryHash = 'entry_hash';

  /// Schema version number.
  static const String version = 'version';

  /// Configuration key.
  static const String key = 'key';

  /// Configuration value.
  static const String value = 'value';

  /// Latest schema version created for new databases.
  static const int currentSchemaVersion = 2;

  /// SQL statements creating tables in dependency order.
  static const List<String> createStatements = <String>[
    '''
CREATE TABLE clients (
  id TEXT PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('holder', 'insured')),
  name TEXT NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other')),
  dob TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)
''',
    '''
CREATE TABLE policies (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL REFERENCES clients(id),
  policy_no TEXT NOT NULL,
  company TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  first_premium_date TEXT NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'lapsed', 'surrendered')),
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)
''',
    '''
CREATE TABLE plans (
  id TEXT PRIMARY KEY,
  policy_id TEXT NOT NULL REFERENCES policies(id),
  category TEXT NOT NULL CHECK (category IN ('life', 'ci', 'hospital', 'accident', 'savings', 'other')),
  plan_name TEXT NOT NULL,
  coverage_amount TEXT,
  payment_term TEXT,
  coverage_period TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)
''',
    '''
CREATE TABLE riders (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL REFERENCES plans(id),
  rider_name TEXT NOT NULL,
  coverage_amount TEXT,
  payment_term TEXT,
  deductible TEXT,
  waiting_period TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)
''',
    '''
CREATE TABLE audit_log (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  event_type TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  metadata TEXT,
  prev_hash TEXT NOT NULL,
  entry_hash TEXT NOT NULL
)
''',
    '''
CREATE TABLE schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
)
''',
    '''
CREATE TABLE app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
  ];

  /// Indexes supporting the planned entity and audit-log queries.
  static const List<String> indexes = <String>[
    'CREATE INDEX idx_clients_role ON clients(role)',
    'CREATE INDEX idx_clients_archived ON clients(archived_at)',
    'CREATE INDEX idx_policies_client ON policies(client_id)',
    'CREATE INDEX idx_policies_archived ON policies(archived_at)',
    'CREATE INDEX idx_plans_policy ON plans(policy_id)',
    'CREATE INDEX idx_plans_category ON plans(category)',
    'CREATE INDEX idx_plans_archived ON plans(archived_at)',
    'CREATE INDEX idx_riders_plan ON riders(plan_id)',
    'CREATE INDEX idx_audit_timestamp ON audit_log(timestamp)',
    'CREATE INDEX idx_audit_event ON audit_log(event_type)',
  ];

  /// Triggers that prevent mutation of persisted audit history.
  ///
  /// Retention purges temporarily remove these triggers while deleting expired
  /// rows, then recreate them before returning.
  static const List<String> auditTriggers = <String>[
    '''
CREATE TRIGGER audit_log_no_update
BEFORE UPDATE ON audit_log
BEGIN
  SELECT RAISE(ABORT, 'audit_log is append-only');
END
''',
    '''
CREATE TRIGGER audit_log_no_delete
BEFORE DELETE ON audit_log
BEGIN
  SELECT RAISE(ABORT, 'audit_log is append-only');
END
''',
  ];
}
