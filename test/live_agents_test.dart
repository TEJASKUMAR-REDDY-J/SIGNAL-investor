// Live end-to-end check against real Yahoo, NSE and Groq. Skipped unless LIVE=1:
//   LIVE=1 flutter test test/live_agents_test.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/pipeline/agents_run.dart';
import 'package:signal_investor/pipeline/scan.dart';
import 'package:signal_investor/sources/groq.dart';
import 'package:signal_investor/sources/net.dart';

void main() {
  final live = Platform.environment['LIVE'] == '1';
  test('agents trade on live data with the AI tool loop', () async {
    final env = File('.env').readAsLinesSync();
    final key = cleanKey(env.firstWhere((l) => l.startsWith('GROQ_API_KEY=')).split('=').skip(1).join('='));
    final m = MarketDb(NativeDatabase.memory());
    final net = Net(timeout: const Duration(seconds: 30));
    // A partial NIFTY 500 scan (80 names) keeps the check to about a minute.
    await runScan(m, net, onProgress: (_, _, _) {}, cancel: CancelToken(), limit: 80, pause: const Duration(milliseconds: 200));
    final status = <String>[];
    final lines = await runAgents(m, net, groqKey: key, nowUtc: DateTime.utc(2026, 10, 14, 5, 30), onStatus: status.add);
    stdout.writeln(status.join('\n'));
    stdout.writeln(lines.join('\n'));
    final runs = await m.select(m.agentRuns).get();
    for (final r in runs) {
      stdout.writeln('--- ${r.agent}: ai=${r.ai} tools=${r.toolCalls}\n${r.summary}\nBULL: ${r.bull}\nBEAR: ${r.bear}\n${r.regime}');
    }
    for (final t in await m.select(m.agentTrades).get()) {
      stdout.writeln('${t.agent} ${t.side} ${t.unitsE4 ~/ 10000} #${t.instrumentId} @${t.priceE4 / 10000}: ${t.reason}');
    }
    expect(runs, hasLength(3));
    expect(runs.where((r) => r.ai), isNotEmpty);
    expect(runs.any((r) => r.toolCalls > 0), isTrue);
    await m.close();
  }, skip: live ? false : 'set LIVE=1 to run against real services', timeout: const Timeout(Duration(minutes: 10)));
}
