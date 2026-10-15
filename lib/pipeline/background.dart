import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../db/db.dart';
import '../db/open_db.dart';
import '../engine/news_score.dart';
import '../sources/groq.dart';
import '../sources/net.dart';
import 'agents_run.dart';
import 'feeds.dart';
import 'refresh.dart';
import 'scan.dart';

// The background job: WorkManager wakes it about once an hour (Android may batch or
// delay it). Each wake: the paper agents trade if they have not yet today (market days
// from 09:45 IST), and the news digest runs once per slot (08:00, 11:00 and 16:00 IST):
// prices, NSE filings and news for everything you hold or follow, labels new
// headlines, warms 40 advisor entries, then posts one notification. Only public
// market data is read: the job opens market.db, never your profile database.

const trackedKey = 'tracked_ids'; // JSON list of instrument ids, written by the app
const digestOnKey = 'digest_on'; // '0' turns the notification off
const _lastDigestKey = 'last_digest_at';
const lastCheckKey = 'last_news_check'; // "<ISO time>|<digest or empty>" for Settings
const lastWakeKey = 'last_bg_wake'; // ISO time of the latest background wake, shown on the Agents tab
const _task = 'signal-hourly';
const _oldTask = 'signal-daily'; // the one-off chain used before 2026-10-15
const digestHoursIst = [8, 11, 16];

/// The latest digest slot at or before [nowUtc].
DateTime lastSlotUtc(DateTime nowUtc) {
  final ist = nowUtc.toUtc().add(const Duration(hours: 5, minutes: 30));
  for (var d = 0; d < 2; d++) {
    for (final h in digestHoursIst.reversed) {
      final slot = DateTime.utc(ist.year, ist.month, ist.day - d, h).subtract(const Duration(hours: 5, minutes: 30));
      if (!slot.isAfter(nowUtc)) return slot;
    }
  }
  throw StateError('unreachable');
}

/// A digest is due when no digest has run since the latest slot.
bool digestDue(DateTime nowUtc, DateTime? lastDigestUtc) => lastDigestUtc == null || lastDigestUtc.isBefore(lastSlotUtc(nowUtc));

Future<void> saveTracked(Set<int> ids) => storage.write(key: trackedKey, value: jsonEncode(ids.toList()..sort()));

Future<Set<int>> loadTracked() async {
  final raw = await storage.read(key: trackedKey);
  return raw == null ? <int>{} : {...(jsonDecode(raw) as List).cast<int>()};
}

/// Hourly periodic work survives a killed run (a one-off chain did not). Called on every app start.
Future<void> scheduleBackground() async {
  await Workmanager().cancelByUniqueName(_oldTask);
  await Workmanager().registerPeriodicTask(
    _task,
    _task,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

Future<void> initBackground() async {
  await Workmanager().initialize(backgroundDispatcher);
  await scheduleBackground();
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await storage.write(key: lastWakeKey, value: DateTime.now().toUtc().toIso8601String());
      await runDaily();
    } catch (_) {
      // Never crash the worker; the next wake tries again.
    }
    return true;
  });
}

final _notes = FlutterLocalNotificationsPlugin();

/// Posts one notification; never throws (no permission, no platform, ...).
Future<void> _notify(int id, String channel, String channelName, String title, String body) async {
  try {
    await _notes.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_signal')));
    await _notes.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(channel, channelName, styleInformation: BigTextStyleInformation(body)),
      ),
    );
  } catch (_) {}
}

Future<bool> requestNotificationPermission() async {
  await _notes.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_signal')));
  return await _notes
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission() ??
      false;
}

/// The job itself; returns the digest text (null when there was nothing new).
/// [manual] (Settings button) summarises the last 24 hours instead of "since the last digest".
Future<String?> runDaily({DateTime? nowUtc, MarketDb? market, Net? net, bool manual = false}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final m = market ?? await openMarket();
  final n = net ?? Net();
  try {
    final profile = (await loadProfiles()).firstOrNull;
    final key = profile == null ? envKey() : cleanKey(await storage.read(key: 'groq_${profile.id}')) ?? envKey();
    // Agents first: they matter most and must fit in Android's ~10 minute window.
    if (!manual && (await agentsDue(m, now)).isNotEmpty) {
      final agentLines = await runAgents(m, n, groqKey: key, nowUtc: now).catchError((Object e) => ['Agents could not run: $e']);
      if (agentLines.isNotEmpty && await storage.read(key: digestOnKey) != '0') {
        await _notify(2, 'agents', 'Paper agents', 'Paper agents traded', agentLines.join(String.fromCharCode(10)));
      }
    }
    final lastDigest = DateTime.tryParse(await storage.read(key: _lastDigestKey) ?? '');
    if (!manual && !digestDue(now, lastDigest)) return null;

    final tracked = await loadTracked();
    Future<(String, String)?> groq() async => key == null ? null : (key, defaultTagModel);
    Set<int> held() => tracked;
    await Refresher(m, n, extra: [filingsStep(m, n, held), newsStep(m, n, held, groq)]).run(tracked, force: true, nowUtc: now);
    if (!manual) {
      try {
        await runScan(m, n, onProgress: (_, _, _) {}, cancel: CancelToken(), limit: 40, nowUtc: now);
      } catch (_) {}
    }

    final since = manual ? now.subtract(const Duration(hours: 24)) : lastDigest ?? now.subtract(const Duration(hours: 12));
    final fresh = await (m.select(m.newsItems)
          ..where((x) => x.publishedAt.isBiggerOrEqualValue(since) & x.instrumentId.isIn(tracked)))
        .get();
    final names = {for (final i in await (m.select(m.instruments)..where((x) => x.id.isIn(tracked))).get()) i.id: i.name};
    final line = digestLine(newsScores(fresh, now, window: now.difference(since)), names);
    if (!manual) await storage.write(key: _lastDigestKey, value: now.toIso8601String());
    await storage.write(key: lastCheckKey, value: '${now.toIso8601String()}|${line ?? ''}');
    if (line != null && await storage.read(key: digestOnKey) != '0') {
      final ist = now.add(const Duration(hours: 5, minutes: 30));
      await _notify(1, 'news_pulse', 'Daily news pulse', ist.hour < 12 ? 'Morning news pulse' : 'Evening news pulse', line);
    }
    return line;
  } finally {
    if (market == null) await m.close();
  }
}
