import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/db/open_db.dart';
import 'package:sqlite3/sqlite3.dart' as s3;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sigdb'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('profile db is encrypted, audited, and unreadable without key', () async {
    final f = File('${dir.path}/profile_test.db');
    final key = newHexKey();
    final db = ProfileDb(openEncrypted(f, key));
    final id = await db.addTx(TransactionsCompanion.insert(
        instrumentId: 1, date: '2025-01-01', type: 'buy', unitsE4: 100000, priceE4: 1000000));
    final t = (await db.watchTxs().first).single;
    await db.editTx(t.copyWith(note: 'edited'));
    await db.deleteTx(id);
    final audit = await db.select(db.auditLog).get();
    expect(audit.map((a) => a.action), ['insert', 'edit', 'delete']);
    await db.close();

    final bytes = f.readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));

    // Opening without a key behaves like plain sqlite3: not a database.
    final plain = s3.sqlite3.open(f.path);
    expect(() => plain.select('SELECT * FROM transactions'), throwsA(isA<s3.SqliteException>()));
    plain.close();

    // Wrong key fails at open.
    final bad = ProfileDb(openEncrypted(f, newHexKey()));
    await expectLater(bad.select(bad.transactions).get(), throwsA(anything));
    await bad.close();

    // Right key reopens.
    final again = ProfileDb(openEncrypted(f, key));
    expect(await again.select(again.auditLog).get(), hasLength(3));
    await again.close();

    // Left for the manual plain-sqlite3 check (python -c "import sqlite3 ...").
    f.copySync('${Directory.systemTemp.path}/signal_encryption_demo.db');
  });

  test('refuses a plaintext database file', () {
    final f = File('${dir.path}/plain.db');
    // No PRAGMA key: SQLite3MultipleCiphers writes a plaintext file.
    final p = s3.sqlite3.open(f.path);
    p.execute('CREATE TABLE x(a); INSERT INTO x VALUES (1);');
    p.close();
    expect(String.fromCharCodes(f.readAsBytesSync().take(15)), 'SQLite format 3');
    expect(() => openEncrypted(f, newHexKey()), throwsStateError);
  });

  test('rejects malformed key (no SQL injection via key)', () {
    expect(() => openEncrypted(File('${dir.path}/x.db'), "'; DROP TABLE x; --"),
        throwsArgumentError);
  });

  test('market db opens encrypted', () async {
    final db = MarketDb(openEncrypted(File('${dir.path}/market.db'), newHexKey()));
    await db.into(db.instruments).insert(InstrumentsCompanion.insert(kind: 'mf', name: 'Test Fund'));
    expect(await db.select(db.instruments).get(), hasLength(1));
    await db.close();
  });
}
