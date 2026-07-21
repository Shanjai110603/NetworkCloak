import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────
// TABLE DEFINITIONS  (all 15 from SDES spec)
// ─────────────────────────────────────────────────────────────

/// Persistent key-value settings table.
/// Stores configuration categories (e.g., VPN settings, UI selections)
/// mapping keys to values and dynamic value types.
class Settings extends Table {
  TextColumn get category => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get valueType => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {category, key};
}

/// Network profiles table.
/// Represents a profile mode (e.g., Home, Work, Travel, Public Wi-Fi)
/// that holds specific rule presets or active statuses.
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get configJson => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class FirewallRules extends Table {
  TextColumn get id => text()();
  TextColumn get appId => text().nullable()();
  TextColumn get action => text()();
  IntColumn get priority => integer()();
  TextColumn get conditionsJson => text()();
  TextColumn get profileId => text().nullable()();
  BoolColumn get isGlobal => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class TemporaryRules extends Table {
  TextColumn get id => text()();
  TextColumn get appId => text()();
  TextColumn get action => text()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  TextColumn get previousRuleId => text().nullable()();
  TextColumn get conditionsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionRules extends Table {
  TextColumn get id => text()();
  TextColumn get appId => text()();
  TextColumn get action => text()();
  TextColumn get sessionId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class TrustedNetworks extends Table {
  TextColumn get id => text()();
  TextColumn get ssid => text()();
  TextColumn get bssid => text()();
  TextColumn get trustLevel => text()();
  TextColumn get profileId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class DnsProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get provider => text()();
  TextColumn get protocol => text()();
  TextColumn get endpoint => text()();
  TextColumn get blocklists => text()(); // JSON array of enabled category IDs

  @override
  Set<Column> get primaryKey => {id};
}

class DnsBlocklists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get url => text()();
  TextColumn get checksum => text().nullable()();
  IntColumn get updatedAt => integer()();
  IntColumn get domainCount => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DnsLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get domain => text()();
  TextColumn get action => text()();
  TextColumn get category => text().nullable()();
  IntColumn get latencyMs => integer().nullable()();
  TextColumn get appId => text().nullable()();
  TextColumn get countryCode => text().nullable()();
  IntColumn get timestamp => integer()();
}

class Applications extends Table {
  TextColumn get id => text()();
  TextColumn get packageName => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get version => text().nullable()();
  IntColumn get firstSeen => integer()();
  BlobColumn get iconBytes => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ApplicationStats extends Table {
  TextColumn get id => text()();
  TextColumn get appId => text()();
  IntColumn get connections => integer().withDefault(const Constant(0))();
  IntColumn get blocked => integer().withDefault(const Constant(0))();
  IntColumn get bytesSent => integer().withDefault(const Constant(0))();
  IntColumn get bytesRecv => integer().withDefault(const Constant(0))();
  TextColumn get statDate => text()(); // YYYY-MM-DD

  @override
  Set<Column> get primaryKey => {id};
}

class ConnectionHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get appId => text()();
  TextColumn get destHost => text()();
  TextColumn get destIp => text().nullable()();
  IntColumn get port => integer().nullable()();
  TextColumn get protocol => text().nullable()();
  TextColumn get ruleId => text().nullable()();
  TextColumn get action => text()();
  IntColumn get bytes => integer().nullable()();
  TextColumn get countryCode => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get timestamp => integer()();
}

class Alerts extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get severity => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get appId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('unread'))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class LiveConnections extends Table {
  TextColumn get id => text()();
  TextColumn get appId => text()();
  TextColumn get dest => text()();
  TextColumn get protocol => text()();
  IntColumn get startedAt => integer()();
  IntColumn get bytes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SchemaVersions extends Table {
  IntColumn get version => integer()();
  IntColumn get appliedAt => integer()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {version};
}

// ─────────────────────────────────────────────────────────────
// DATABASE CLASS
// ─────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Settings,
  Profiles,
  FirewallRules,
  TemporaryRules,
  SessionRules,
  TrustedNetworks,
  DnsProfiles,
  DnsBlocklists,
  DnsLogs,
  Applications,
  ApplicationStats,
  ConnectionHistory,
  Alerts,
  LiveConnections,
  SchemaVersions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Create secondary indexes manually (Drift 2.11 compatible)
          await _createIndexes();
          // Record schema version
          await into(schemaVersions).insert(SchemaVersionsCompanion(
            version: const Value(2),
            appliedAt: Value(DateTime.now().millisecondsSinceEpoch),
            description: const Value('Database setup v2 — Added coordinates support'),
          ));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Version 1 to 2 migration: add latitude/longitude columns to connection_history table
            await customStatement('ALTER TABLE connection_history ADD COLUMN latitude REAL');
            await customStatement('ALTER TABLE connection_history ADD COLUMN longitude REAL');
            // Insert migration record
            await into(schemaVersions).insert(SchemaVersionsCompanion(
              version: const Value(2),
              appliedAt: Value(DateTime.now().millisecondsSinceEpoch),
              description: const Value('Migration from v1 to v2: added coordinate caching to connection_history'),
            ));
          }
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fr_app ON firewall_rules(app_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fr_profile ON firewall_rules(profile_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tr_end ON temporary_rules(end_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_dl_ts ON dns_logs(timestamp)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_dl_app ON dns_logs(app_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_as_app_date ON application_stats(app_id, stat_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ch_app ON connection_history(app_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ch_ts ON connection_history(timestamp)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ch_dest ON connection_history(dest_host)',
    );
  }

  // ── Convenience query helpers ──────────────────────────────

  /// Fetch all non-expired temporary rules (for in-memory rule engine cache)
  Future<List<TemporaryRule>> activeTemporaryRules() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(temporaryRules)
          ..where((t) => t.endAt.isBiggerThanValue(now)))
        .get();
  }

  /// Fetch all session rules for the given sessionId
  Future<List<SessionRule>> sessionRulesFor(String sessionId) {
    return (select(sessionRules)
          ..where((s) => s.sessionId.equals(sessionId)))
        .get();
  }

  /// Clear all live connections (called on VPN restart)
  Future<void> clearLiveConnections() => delete(liveConnections).go();

  /// Upsert an application entry
  Future<void> upsertApplication(ApplicationsCompanion entry) {
    return into(applications).insertOnConflictUpdate(entry);
  }
}

// ─────────────────────────────────────────────────────────────
// PLATFORM CONNECTION FACTORY
// ─────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'network_cloak.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
