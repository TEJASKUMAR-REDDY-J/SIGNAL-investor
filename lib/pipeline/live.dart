import 'package:drift/drift.dart';

import '../db/db.dart';
import '../sources/net.dart';
import '../sources/yahoo.dart';

/// Home strip, in display order. The NIFTY 50 row is shared with the refresher ('index' alias).
const indexTickers = {'^NSEI': 'NIFTY 50', '^BSESN': 'SENSEX', '^NSEBANK': 'NIFTY BANK'};

Future<List<Instrument>> ensureIndices(MarketDb m) async {
  final out = <Instrument>[];
  for (final e in indexTickers.entries) {
    var i = await (m.select(m.instruments)..where((x) => x.yahooTicker.equals(e.key))).getSingleOrNull();
    if (i == null) {
      final id = await m.into(m.instruments).insert(InstrumentsCompanion.insert(
          kind: 'index', name: e.value, yahooTicker: Value(e.key), aliases: Value(e.key == '^NSEI' ? 'index' : '')));
      i = await (m.select(m.instruments)..where((x) => x.id.equals(id))).getSingle();
    }
    out.add(i);
  }
  return out;
}

/// One batched request per 20 tickers. Each quote is also stored as today's
/// close, so holdings, charts and the day's change use it straight away.
Future<Map<int, Quote>> liveQuotes(MarketDb m, Net net, Iterable<Instrument> inst) async {
  final byTicker = {for (final i in inst) if (i.yahooTicker != null) i.yahooTicker!: i};
  if (byTicker.isEmpty) return const {};
  final quotes = await yahooQuotes(net, byTicker.keys.toList());
  final out = <int, Quote>{};
  for (final q in quotes) {
    final i = byTicker[q.ticker];
    if (i == null) continue;
    await m.putPrices(i.id, 'yahoo', [(q.day, q.priceE4)]);
    out[i.id] = q;
  }
  return out;
}
