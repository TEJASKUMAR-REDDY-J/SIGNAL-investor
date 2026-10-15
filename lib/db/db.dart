import 'package:drift/drift.dart';

import '../engine/lots.dart';

part 'db.g.dart';

extension TxRow on Transaction {
  Tx get tx => Tx(id, parseDay(date), TxType.values.byName(type), unitsE4,
      priceE4, feesPaise, goalId);
}

// Money: *Paise ints. Units/prices: *E4 ints (x1e4). Dates: 'YYYY-MM-DD'.

// ---- market.db: public data shared by all profiles ----

class Instruments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // 'stock' | 'mf'
  TextColumn get yahooTicker => text().nullable()();
  TextColumn get nseSymbol => text().nullable()();
  TextColumn get schemeCode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get aliases => text().withDefault(const Constant(''))();
}

class Prices extends Table {
  IntColumn get instrumentId => integer()();
  TextColumn get date => text()();
  IntColumn get closeE4 => integer()();
  TextColumn get source => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {instrumentId, date, source};
}

class NewsItems extends Table {
  TextColumn get urlHash => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get publisher => text()();
  DateTimeColumn get publishedAt => dateTime()();
  IntColumn get instrumentId => integer().nullable()();
  TextColumn get label => text().nullable()();
  RealColumn get confidence => real().nullable()();
  TextColumn get reason => text().nullable()();
  @override
  Set<Column> get primaryKey => {urlHash};
}

class Filings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get instrumentId => integer()();
  TextColumn get date => text()();
  TextColumn get category => text()();
  TextColumn get subject => text()();
  TextColumn get url => text()();
}

class FetchLog extends Table {
  TextColumn get source => text()();
  DateTimeColumn get lastOkAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get rows => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {source};
}

/// NSE trading holidays fetched at runtime (bundled list covers 2026).
class Holidays extends Table {
  TextColumn get date => text()();
  TextColumn get name => text()();
  @override
  Set<Column> get primaryKey => {date};
}

/// Every NSE-listed equity (EQUITY_L.csv); [nifty500] marks scan members.
@DataClassName('Listing')
class Universe extends Table {
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  TextColumn get industry => text().withDefault(const Constant(''))();
  TextColumn get isin => text().withDefault(const Constant(''))();
  BoolColumn get nifty500 => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {symbol};
}

/// Latest fundamentals per NSE symbol (scan cache), raw JSON numbers.
@DataClassName('Fundamental')
class Fundamentals extends Table {
  TextColumn get symbol => text()();
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {symbol};
}

// ---- Autonomous paper agents (public-market simulation; lives here so the
// background job can trade without opening the personal profile database) ----

/// Every paper order an agent placed, with its reason.
class AgentTrades extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get agent => text()(); // daily | weekly | monthly
  IntColumn get instrumentId => integer()();
  TextColumn get date => text()(); // IST trading day
  DateTimeColumn get at => dateTime()();
  TextColumn get side => text()(); // buy | sell
  IntColumn get unitsE4 => integer()();
  IntColumn get priceE4 => integer()();
  IntColumn get feesPaise => integer().withDefault(const Constant(0))();
  TextColumn get reason => text().withDefault(const Constant(''))();
}

/// One row per agent per run: what it concluded and where it stood after.
class AgentRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get agent => text()();
  TextColumn get date => text()();
  DateTimeColumn get at => dateTime()();
  TextColumn get summary => text()();
  IntColumn get valuePaise => integer()(); // cash + holdings after the run
  IntColumn get cashPaise => integer()();
  BoolColumn get ai => boolean().withDefault(const Constant(false))(); // AI reviewed the plan
  TextColumn get bull => text().nullable()(); // the AI's case for its trades
  TextColumn get bear => text().nullable()(); // and against
  TextColumn get regime => text().nullable()(); // market mood that day
  IntColumn get toolCalls => integer().withDefault(const Constant(0))(); // data look-ups the AI made
}

/// Lessons an agent wrote for itself after reviewing its own trades (reflection memory).
@DataClassName('AgentMemory')
class AgentMemories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get agent => text()();
  DateTimeColumn get at => dateTime()();
  TextColumn get body => text()();
}

/// What the user tells the agents; every run reads these.
class AgentNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get body => text()();
  TextColumn get agent => text().nullable()(); // null = all agents
}

@DriftDatabase(tables: [
  Instruments, Prices, NewsItems, Filings, FetchLog, Holidays, Universe, Fundamentals, AgentTrades, AgentRuns, AgentNotes,
  AgentMemories
])
class MarketDb extends _$MarketDb {
  MarketDb(super.e);
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(holidays);
            await m.createTable(universe);
            await m.createTable(fundamentals);
          }
          if (from < 3) {
            await m.createTable(agentTrades);
            await m.createTable(agentRuns);
            await m.createTable(agentNotes);
          }
          if (from >= 3 && from < 4) {
            await m.addColumn(agentRuns, agentRuns.bull);
            await m.addColumn(agentRuns, agentRuns.bear);
            await m.addColumn(agentRuns, agentRuns.regime);
            await m.addColumn(agentRuns, agentRuns.toolCalls);
          }
          if (from < 4) await m.createTable(agentMemories);
        },
        beforeOpen: (_) => dedupeInstruments(),
      );

  /// One row per NSE symbol, Yahoo ticker and AMFI code. The app and the background job
  /// once inserted the same stocks at the same time, and every later lookup failed with
  /// "Too many elements". Merges any duplicates into the oldest row (recorded in
  /// instrument_merges so the profile database can follow), then enforces uniqueness.
  Future<void> dedupeInstruments() => transaction(() async {
        await customStatement('CREATE TABLE IF NOT EXISTS instrument_merges (old_id INTEGER PRIMARY KEY, new_id INTEGER NOT NULL)');
        for (final col in const ['nse_symbol', 'yahoo_ticker', 'scheme_code']) {
          final dups = await customSelect('SELECT i.id AS old, k.keep AS new FROM instruments i JOIN '
                  '(SELECT $col AS v, MIN(id) AS keep FROM instruments WHERE $col IS NOT NULL GROUP BY $col HAVING COUNT(*) > 1) k '
                  'ON i.$col = k.v WHERE i.id <> k.keep')
              .get();
          for (final r in dups) {
            final args = [r.read<int>('new'), r.read<int>('old')];
            await customStatement('INSERT OR REPLACE INTO instrument_merges (old_id, new_id) VALUES (?2, ?1)', args);
            for (final t in const ['prices', 'news_items', 'filings', 'agent_trades']) {
              await customStatement('UPDATE OR IGNORE $t SET instrument_id = ?1 WHERE instrument_id = ?2', args);
              await customStatement('DELETE FROM $t WHERE instrument_id = ?2', args); // rows the kept one already had
            }
            await customStatement('DELETE FROM instruments WHERE id = ?2', args);
          }
          await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS ux_instruments_$col ON instruments ($col) WHERE $col IS NOT NULL');
        }
      });

  /// Duplicate instrument ids merged away (old -> kept), for [ProfileDb.applyMerges].
  Future<Map<int, int>> instrumentMerges() async => {
        for (final r in await customSelect('SELECT old_id, new_id FROM instrument_merges').get())
          r.read<int>('old_id'): r.read<int>('new_id'),
      };

  /// The instrument with this key, created if missing. Safe when another process
  /// inserts the same one at the same moment (the unique index keeps one row).
  Future<Instrument> instrumentFor(
      {required String kind,
      required String name,
      String? nseSymbol,
      String? yahooTicker,
      String? schemeCode,
      String aliases = ''}) async {
    Future<Instrument?> find() => (select(instruments)
          ..where((i) => nseSymbol != null
              ? i.nseSymbol.equals(nseSymbol)
              : schemeCode != null
                  ? i.schemeCode.equals(schemeCode)
                  : i.yahooTicker.equals(yahooTicker!))
          ..orderBy([(i) => OrderingTerm.asc(i.id)])
          ..limit(1))
        .getSingleOrNull();
    final hit = await find();
    if (hit != null) return hit;
    await into(instruments).insert(
        InstrumentsCompanion.insert(
            kind: kind,
            name: name,
            nseSymbol: Value(nseSymbol),
            yahooTicker: Value(yahooTicker),
            schemeCode: Value(schemeCode),
            aliases: Value(aliases)),
        mode: InsertMode.insertOrIgnore);
    return (await find())!;
  }

  Future<void> logFetch(String source, {Object? error, int rows = 0, DateTime? at}) async {
    final now = at ?? DateTime.now();
    final old = await (select(fetchLog)..where((f) => f.source.equals(source))).getSingleOrNull();
    await into(fetchLog).insertOnConflictUpdate(FetchLogCompanion.insert(
      source: source,
      lastAttemptAt: Value(now),
      lastOkAt: Value(error == null ? now : old?.lastOkAt),
      lastError: Value(error?.toString()),
      rows: Value(rows),
    ));
  }

  Future<FetchLogData?> fetchState(String source) =>
      (select(fetchLog)..where((f) => f.source.equals(source))).getSingleOrNull();

  Future<void> putPrices(int instrumentId, String source, Iterable<(String, int)> rows) {
    final now = DateTime.now();
    return batch((b) => b.insertAllOnConflictUpdate(prices, [
          for (final (d, c) in rows)
            PricesCompanion.insert(instrumentId: instrumentId, date: d, closeE4: c, source: source, fetchedAt: now),
        ]));
  }
}

// ---- profile_<id>.db: everything personal ----

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get targetDate => text()();
  IntColumn get targetPaise => integer()();
  // Show amounts in the goal's own terms, e.g. "month abroad" = Rs 1,20,000.
  TextColumn get unitName => text().nullable()();
  IntColumn get unitPaise => integer().nullable()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get instrumentId => integer()();
  TextColumn get date => text()();
  TextColumn get type => text()(); // buy | sell | sip | dividend
  IntColumn get unitsE4 => integer()();
  IntColumn get priceE4 => integer()(); // dividend: total amount
  IntColumn get feesPaise => integer().withDefault(const Constant(0))();
  IntColumn get goalId => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  // STT is not deductible from capital gains (s.48), so it is kept out of cost.
  IntColumn get sttPaise => integer().withDefault(const Constant(0))();
}

class SipPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get instrumentId => integer()();
  IntColumn get amountPaise => integer()();
  IntColumn get dayOfMonth => integer()();
  TextColumn get start => text()();
  TextColumn get end => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

@DataClassName('Thesis')
class Theses extends Table {
  IntColumn get instrumentId => integer()();
  TextColumn get whyBought => text()();
  TextColumn get breaksIf => text()();
  TextColumn get reviewDate => text().nullable()();
  BoolColumn get broken => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {instrumentId};
}

class Signals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get instrumentId => integer()();
  IntColumn get rule => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get inputsJson => text()();
  TextColumn get ruleVersion => text()();
  TextColumn get status => text()(); // open | closed
  TextColumn get userAction => text().nullable()(); // planned | dismissed | done
  DateTimeColumn get actedAt => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Simulator: paper trades at real prices with virtual cash.
class PaperTrades extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get instrumentId => integer()();
  TextColumn get date => text()();
  TextColumn get type => text()(); // buy | sell
  IntColumn get unitsE4 => integer()();
  IntColumn get priceE4 => integer()();
  TextColumn get reason => text().withDefault(const Constant(''))();
}

/// Stocks and funds to follow without owning them (prices and news tracked).
@DataClassName('Watch')
class Watchlist extends Table {
  IntColumn get instrumentId => integer()();
  DateTimeColumn get addedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {instrumentId};
}

class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get action => text()();
  TextColumn get detail => text()();
}

/// Per-profile view of an instrument: core (index) or satellite (picks).
class HoldingPrefs extends Table {
  IntColumn get instrumentId => integer()();
  TextColumn get bucket => text().withDefault(const Constant('core'))();
  @override
  Set<Column> get primaryKey => {instrumentId};
}

class ProfileSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Goals, Transactions, SipPlans, Theses, Signals, AuditLog, HoldingPrefs, ProfileSettings, PaperTrades, Watchlist
])
class ProfileDb extends _$ProfileDb {
  ProfileDb(super.e);
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(holdingPrefs);
            await m.createTable(profileSettings);
          }
          if (from < 3) {
            await m.addColumn(transactions, transactions.sttPaise);
            await m.addColumn(theses, theses.broken);
            await m.addColumn(signals, signals.actedAt);
            await m.addColumn(signals, signals.note);
            await m.createTable(paperTrades);
            await m.addColumn(goals, goals.unitName);
            await m.addColumn(goals, goals.unitPaise);
          }
          if (from < 4) await m.createTable(watchlist);
        },
      );

  /// Runs [f] and its audit row in one transaction.
  Future<T> audited<T>(String action, String detail, Future<T> Function() f) =>
      transaction(() async {
        final r = await f();
        await into(auditLog).insert(
            AuditLogCompanion.insert(at: DateTime.now(), action: action, detail: detail));
        return r;
      });

  Future<int> addTx(TransactionsCompanion t) => transaction(() async {
        final id = await into(transactions).insert(t);
        await into(auditLog).insert(AuditLogCompanion.insert(
            at: DateTime.now(), action: 'insert', detail: 'transaction $id ${t.type.value}'));
        return id;
      });

  Future<void> editTx(Transaction t) =>
      audited('edit', 'transaction ${t.id} ${t.type}', () => update(transactions).replace(t));

  Future<void> deleteTx(int id) => audited('delete', 'transaction $id',
      () => (delete(transactions)..where((t) => t.id.equals(id))).go());

  /// Undo of a delete: same row, same id.
  Future<void> restoreTx(Transaction t) => audited('restore', 'transaction ${t.id}', () => into(transactions).insert(t));

  /// Follows instrument merges from the market database (see MarketDb.dedupeInstruments).
  Future<void> applyMerges(Map<int, int> merges) async {
    if (merges.isEmpty) return;
    await transaction(() async {
      for (final e in merges.entries) {
        final args = [e.value, e.key];
        for (final t in const ['transactions', 'sip_plans', 'theses', 'signals', 'paper_trades', 'watchlist', 'holding_prefs']) {
          await customStatement('UPDATE OR IGNORE $t SET instrument_id = ?1 WHERE instrument_id = ?2', args);
          await customStatement('DELETE FROM $t WHERE instrument_id = ?2', args);
        }
      }
    });
  }

  Stream<List<Transaction>> watchTxs([int? instrumentId]) {
    final q = select(transactions)
      ..orderBy([(t) => OrderingTerm.asc(t.date), (t) => OrderingTerm.asc(t.id)]);
    if (instrumentId != null) q.where((t) => t.instrumentId.equals(instrumentId));
    return q.watch();
  }

  Future<int> saveGoal(GoalsCompanion g) => g.id.present
      ? audited('edit', 'goal ${g.id.value}', () async {
          await (update(goals)..where((x) => x.id.equals(g.id.value))).write(g);
          return g.id.value;
        })
      : transaction(() async {
          final id = await into(goals).insert(g);
          await into(auditLog).insert(
              AuditLogCompanion.insert(at: DateTime.now(), action: 'insert', detail: 'goal $id'));
          return id;
        });

  /// Untags transactions first so no row points at a missing goal.
  Future<void> deleteGoal(int id) => audited('delete', 'goal $id', () async {
        await (update(transactions)..where((t) => t.goalId.equals(id)))
            .write(const TransactionsCompanion(goalId: Value(null)));
        await (delete(goals)..where((g) => g.id.equals(id))).go();
      });

  Future<int> saveSip(SipPlansCompanion p) => p.id.present
      ? audited('edit', 'sip_plan ${p.id.value}', () async {
          await (update(sipPlans)..where((x) => x.id.equals(p.id.value))).write(p);
          return p.id.value;
        })
      : transaction(() async {
          final id = await into(sipPlans).insert(p);
          await into(auditLog).insert(
              AuditLogCompanion.insert(at: DateTime.now(), action: 'insert', detail: 'sip_plan $id'));
          return id;
        });

  Future<void> deleteSip(int id) => audited('delete', 'sip_plan $id',
      () => (delete(sipPlans)..where((p) => p.id.equals(id))).go());

  Future<void> saveThesis(ThesesCompanion t) => audited('edit',
      'thesis ${t.instrumentId.value}', () => into(theses).insertOnConflictUpdate(t));

  Future<void> setBucket(int instrumentId, String bucket) => audited('edit',
      'bucket $instrumentId $bucket',
      () => into(holdingPrefs).insertOnConflictUpdate(
          HoldingPrefsCompanion.insert(instrumentId: Value(instrumentId), bucket: Value(bucket))));

  Future<void> setThesisBroken(int instrumentId, bool broken) =>
      audited('edit', 'thesis_broken $instrumentId $broken', () async {
        await (update(theses)..where((t) => t.instrumentId.equals(instrumentId)))
            .write(ThesesCompanion(broken: Value(broken)));
      });

  /// One open signal per (instrument, rule); refreshes its inputs while open.
  Future<void> upsertSignal(int instrumentId, int rule, String inputsJson, String ruleVersion) async {
    final open = await (select(signals)
          ..where((s) => s.instrumentId.equals(instrumentId) & s.rule.equals(rule) & s.status.equals('open')))
        .getSingleOrNull();
    if (open == null) {
      await audited(
          'insert',
          'signal rule $rule',
          () => into(signals).insert(SignalsCompanion.insert(
              instrumentId: instrumentId,
              rule: rule,
              createdAt: DateTime.now(),
              inputsJson: inputsJson,
              ruleVersion: ruleVersion,
              status: 'open')));
    } else if (open.inputsJson != inputsJson) {
      await (update(signals)..where((s) => s.id.equals(open.id)))
          .write(SignalsCompanion(inputsJson: Value(inputsJson), ruleVersion: Value(ruleVersion)));
    }
  }

  /// Closes open signals of [rules] that no longer fire (planned ones stay).
  Future<void> closeSignalsExcept(Set<(int, int)> firing, Set<int> rules) async {
    final open = await (select(signals)..where((s) => s.status.equals('open'))).get();
    for (final s in open) {
      if (rules.contains(s.rule) && !firing.contains((s.instrumentId, s.rule)) && s.userAction != 'planned') {
        await (update(signals)..where((x) => x.id.equals(s.id)))
            .write(const SignalsCompanion(status: Value('closed')));
      }
    }
  }

  Future<void> actOnSignal(int id, String action, {String note = ''}) =>
      audited('edit', 'signal $id $action', () async {
        await (update(signals)..where((s) => s.id.equals(id))).write(SignalsCompanion(
            userAction: Value(action),
            actedAt: Value(DateTime.now()),
            note: Value(note),
            status: Value(action == 'planned' ? 'open' : 'closed')));
      });

  Future<int> addPaperTrade(PaperTradesCompanion t) =>
      audited('insert', 'paper_trade ${t.type.value}', () => into(paperTrades).insert(t));

  Future<void> setWatched(int instrumentId, bool on) => audited('edit', 'watch $instrumentId $on', () async {
        if (on) {
          await into(watchlist).insertOnConflictUpdate(WatchlistCompanion.insert(instrumentId: Value(instrumentId), addedAt: DateTime.now()));
        } else {
          await (delete(watchlist)..where((w) => w.instrumentId.equals(instrumentId))).go();
        }
      });

  Future<String?> setting(String key) async =>
      (await (select(profileSettings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) => audited('edit', 'setting $key',
      () => into(profileSettings).insertOnConflictUpdate(
          ProfileSettingsCompanion.insert(key: key, value: value)));
}
