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
import 'feeds.dart';
import 'refresh.dart';
import 'scan.dart';

// The daily job: at 08:00 IST (before the open) and 16:00 IST (after the close)
// it refreshes prices, NSE filings and news for everything you hold or follow,
// labels new headlines, warms 40 advisor entries, then posts one digest
// notification. Only public market data is read: the job opens market.db,
// never your profile database. Which companies to track is saved by the app.

const trackedKey = 'tracked_ids'; // JSON list of instrument ids, written by the app
const digestOnKey = 'digest_on'; // '0' turns the notification off
const _lastDigestKey = 'last_digest_at';
const lastCheckKey = 'last_news_check'; // "<ISO time>|<digest or empty>" for Settings
const _task = 'signal-daily';
const digestHoursIst = [8, 16];

/// Next 08:00 or 16:00 IST strictly after [nowUtc].
DateTime nextSlotUtc(DateTime nowUtc) {
  final ist = nowUtc.toUtc().add(const Duration(hours: 5, minutes: 30));
  for (var d = 0; d < 2; d++) {
    for (final h in digestHoursIst) {
      final slotIst = DateTime.utc(ist.year, ist.month, ist.day + d, h);
      final slot = slotIst.subtract(const Duration(hours: 5, minutes: 30));
      if (slot.isAfter(nowUtc)) return slot;
    }
  }
  throw StateError('unreachable');
}

Future<void> saveTracked(Set<int> ids) => storage.write(key: trackedKey, value: jsonEncode(ids.toList()..sort()));

Future<Set<int>> loadTracked() async {
  final raw = await storage.read(key: trackedKey);
  return raw == null ? <int>{} : {...(jsonDecode(raw) as List).cast<int>()};
}

/// Called on every app start and after each run; replaces any pending run.
Future<void> scheduleDaily({DateTime? nowUtc}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  await Workmanager().registerOneOffTask(
    _task,
    _task,
    initialDelay: nextSlotUtc(now).difference(now),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

Future<void> initBackground() async {
  await Workmanager().initialize(backgroundDispatcher);
  await scheduleDaily();
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await runDaily();
    } catch (_) {
      // Never crash the worker; the next slot tries again.
    }
    await scheduleDaily();
    return true;
  });
}

final _notes = FlutterLocalNotificationsPlugin();

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
    final tracked = await loadTracked();
    final profile = (await loadProfiles()).firstOrNull;
    final key = profile == null ? envKey() : cleanKey(await storage.read(key: 'groq_${profile.id}')) ?? envKey();
    Future<(String, String)?> groq() async => key == null ? null : (key, defaultTagModel);
    Set<int> held() => tracked;
    await Refresher(m, n, extra: [filingsStep(m, n, held), newsStep(m, n, held, groq)]).run(tracked, force: true, nowUtc: now);
    if (!manual) {
      try {
        await runScan(m, n, onProgress: (_, _, _) {}, cancel: CancelToken(), limit: 40, nowUtc: now);
      } catch (_) {}
    }

    final since = manual
        ? now.subtract(const Duration(hours: 24))
        : DateTime.tryParse(await storage.read(key: _lastDigestKey) ?? '') ?? now.subtract(const Duration(hours: 12));
    final fresh = await (m.select(m.newsItems)
          ..where((x) => x.publishedAt.isBiggerOrEqualValue(since) & x.instrumentId.isIn(tracked)))
        .get();
    final names = {for (final i in await (m.select(m.instruments)..where((x) => x.id.isIn(tracked))).get()) i.id: i.name};
    final line = digestLine(newsScores(fresh, now, window: now.difference(since)), names);
    if (!manual) await storage.write(key: _lastDigestKey, value: now.toIso8601String());
    await storage.write(key: lastCheckKey, value: '${now.toIso8601String()}|${line ?? ''}');
    if (line != null && await storage.read(key: digestOnKey) != '0') {
      await _notes.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_signal')));
      final ist = now.add(const Duration(hours: 5, minutes: 30));
      await _notes.show(
        id: 1,
        title: ist.hour < 12 ? 'Morning news pulse' : 'Evening news pulse',
        body: line,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails('news_pulse', 'Daily news pulse',
              channelDescription: 'Twice a day: what the news says about companies you hold or follow',
              styleInformation: BigTextStyleInformation(line)),
        ),
      );
    }
    return line;
  } finally {
    if (market == null) await m.close();
  }
}
