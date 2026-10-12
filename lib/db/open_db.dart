import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'db.dart';

// resetOnError: false — the default would silently wipe stored DB keys on a
// keystore hiccup, making every database permanently unreadable.
const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device));

class Profile {
  final String id;
  final String name;
  const Profile(this.id, this.name);
  String get dbFile => 'profile_$id.db';
  Map<String, String> toJson() => {'id': id, 'name': name, 'db': dbFile};
}

/// 32 random bytes, hex. Never logged, never exported.
String newHexKey() {
  final r = Random.secure();
  return [for (var i = 0; i < 32; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')]
      .join();
}

final _hex64 = RegExp(r'^[0-9a-f]{64}$');
final _plainHeader = ascii.encode('SQLite format 3\u0000');

/// Opens [file] with SQLite3MultipleCiphers. Throws if the cipher build is
/// missing, the key is wrong, or the file is a plaintext SQLite database.
QueryExecutor openEncrypted(File file, String hexKey) {
  if (!_hex64.hasMatch(hexKey)) throw ArgumentError('bad key format');
  if (file.existsSync() && file.lengthSync() >= 16) {
    final head = file.openSync()..setPositionSync(0);
    final bytes = head.readSync(16);
    head.closeSync();
    var plain = true;
    for (var i = 0; i < 16; i++) {
      if (bytes[i] != _plainHeader[i]) plain = false;
    }
    if (plain) throw StateError('Refusing unencrypted database ${file.uri.pathSegments.last}');
  }
  return NativeDatabase.createInBackground(file, setup: (raw) {
    raw.execute("PRAGMA key = '$hexKey';");
    if (raw.select('PRAGMA cipher;').isEmpty) {
      throw StateError('Database is not encrypted');
    }
    // Fails here (not later) on a wrong key.
    raw.select('SELECT count(*) FROM sqlite_master;');
  });
}

Future<String> _key(String name) async {
  final k = await storage.read(key: name);
  if (k != null) return k;
  final n = newHexKey();
  await storage.write(key: name, value: n);
  return n;
}

Future<File> _file(String name) async =>
    File('${(await getApplicationSupportDirectory()).path}/$name');

Future<MarketDb> openMarket() async =>
    MarketDb(openEncrypted(await _file('market.db'), await _key('key_market')));

/// Key must already exist for an existing profile; a missing key means the
/// data is unrecoverable, so never mint a fresh one over an existing file.
Future<ProfileDb> openProfile(Profile p) async {
  final f = await _file(p.dbFile);
  final k = await storage.read(key: 'key_${p.id}');
  if (k == null) {
    if (f.existsSync()) throw StateError('Key for this profile is missing');
    throw StateError('Profile not initialised');
  }
  return ProfileDb(openEncrypted(f, k));
}

Future<List<Profile>> loadProfiles() async {
  final raw = await storage.read(key: 'profiles');
  if (raw == null) return [];
  return [
    for (final m in (jsonDecode(raw) as List).cast<Map>())
      Profile(m['id'] as String, m['name'] as String),
  ];
}

Future<Profile> createProfile(String name) async {
  final list = await loadProfiles();
  final id = newHexKey().substring(0, 12);
  final p = Profile(id, name.trim());
  await storage.write(key: 'key_$id', value: newHexKey());
  await storage.write(
      key: 'profiles', value: jsonEncode([...list, p].map((e) => e.toJson()).toList()));
  return p;
}
