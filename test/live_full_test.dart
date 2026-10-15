// Live phone-flow check (fresh install -> agents -> background job). Skipped unless LIVE=1:
//   LIVE=1 flutter test test/live_full_test.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/pipeline/agents_run.dart';
import 'package:signal_investor/pipeline/background.dart';
import 'package:signal_investor/sources/groq.dart';
import 'package:signal_investor/sources/net.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // real network for this live check
  final live = Platform.environment['LIVE'] == '1';
  test('fresh install: full scan, all three agents trade, then the background job on the same data', () async {
    final env = File('.env').readAsLinesSync();
    final key = cleanKey(env.firstWhere((l) => l.startsWith('GROQ_API_KEY=')).split('=').skip(1).join('='));
    final m = MarketDb(NativeDatabase.memory());
    final net = Net();
    final sw = Stopwatch()..start();
    var last = '';
    final lines = await runAgents(m, net, groqKey: key, onStatus: (s) {
      if (s.split(':').first != last.split(':').first) stdout.writeln('[${sw.elapsed.inSeconds}s] $s');
      last = s;
    });
    stdout.writeln(lines.join('\n'));
    final runs = await m.select(m.agentRuns).get();
    for (final r in runs) {
      stdout.writeln('--- ${r.agent}: ai=${r.ai} tools=${r.toolCalls} ${r.summary}');
    }
    expect(runs, hasLength(3));
    expect(lines.where((l) => l.contains('skipped')), isEmpty);
    final trades = await m.select(m.agentTrades).get();
    for (final k in ['daily', 'weekly', 'monthly']) {
      final spent = trades.where((t) => t.agent == k && t.side == 'buy').fold(0, (a, t) => a + t.unitsE4 * t.priceE4 ~/ 1000000);
      stdout.writeln('$k invested Rs ${spent ~/ 100}');
      expect(spent, greaterThan(0), reason: '$k must invest');
    }
    expect(await runAgents(m, net, groqKey: key), isEmpty, reason: 'once per day');

    // Background job: agents due again (runs cleared), digest due (never ran).
    await m.delete(m.agentRuns).go();
    await m.delete(m.agentTrades).go();
    FlutterSecureStorage.setMockInitialValues({'tracked_ids': '[]'});
    sw.reset();
    await runDaily(market: m, net: net);
    stdout.writeln('background job ${sw.elapsed.inSeconds}s');
    expect(await m.select(m.agentRuns).get(), hasLength(3));
    await m.close();
  }, skip: live ? false : 'set LIVE=1 to run against real services', timeout: const Timeout(Duration(minutes: 25)));
}
