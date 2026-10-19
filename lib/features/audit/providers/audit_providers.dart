/// Loads read-only audit history according to the active filter and page size.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audit/audit_entry.dart';
import '../../../core/audit/audit_event_type.dart';
import '../../../providers/app_providers.dart';

/// Filter and page size used to load persisted audit entries.
class AuditFilter {
  /// Creates an audit filter.
  const AuditFilter({this.eventType, this.from, this.to, this.limit = 100});

  /// Event type to include, or null for all events.
  final AuditEventType? eventType;

  /// Inclusive UTC start timestamp.
  final DateTime? from;

  /// Inclusive UTC end timestamp.
  final DateTime? to;

  /// Maximum number of newest matching entries to return.
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is AuditFilter &&
      other.eventType == eventType &&
      other.from == from &&
      other.to == to &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(eventType, from, to, limit);
}

/// Loads newest audit entries for the selected filter.
final auditEntriesProvider =
    FutureProvider.family<List<AuditEntry>, AuditFilter>((
      Ref ref,
      AuditFilter filter,
    ) async {
      final repository = await ref.watch(auditRepositoryProvider.future);
      return repository.findAll(
        eventType: filter.eventType,
        from: filter.from,
        to: filter.to,
        limit: filter.limit,
      );
    });
