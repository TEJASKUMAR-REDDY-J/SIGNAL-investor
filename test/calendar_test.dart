import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/calendar.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/portfolio.dart';

DateTime d(String s) => parseDay(s);

/// IST wall-clock time -> UTC instant.
DateTime ist(int y, int m, int day, int h, [int min = 0]) =>
    DateTime.utc(y, m, day, h, min).subtract(const Duration(hours: 5, minutes: 30));

void main() {
  test('weekends and NSE holidays are not trading days', () {
    expect(nse.isTradingDay(d('2026-10-12')), isTrue); // Monday
    expect(nse.isTradingDay(d('2026-10-10')), isFalse); // Saturday
    expect(nse.isTradingDay(d('2026-10-20')), isFalse); // Dussehra
    expect(nse.closedReason(d('2026-10-20')), 'Dussehra');
    expect(nse.closedReason(d('2026-10-11')), 'Sunday');
    expect(nse.closedReason(d('2026-10-21')), isNull);
    expect(nse.knows(d('2026-05-01')), isTrue);
    expect(nse.knows(d('2025-05-01')), isFalse); // falls back to weekends only
  });

  test('last close: weekday before/after 16:00, weekend, holiday', () {
    // Tue 13 Oct 2026 10:00 IST -> Mon 12 Oct close.
    expect(nse.lastTradingDay(ist(2026, 10, 13, 10)), d('2026-10-12'));
    // Tue 13 Oct 16:05 IST -> today's close.
    expect(nse.lastTradingDay(ist(2026, 10, 13, 16, 5)), d('2026-10-13'));
    expect(nse.lastCloseUtc(ist(2026, 10, 13, 16, 5)), ist(2026, 10, 13, 16));
    // Sunday -> Friday.
    expect(nse.lastTradingDay(ist(2026, 10, 18, 12)), d('2026-10-16'));
    // Wed 21 Oct 09:00 after Dussehra Tue -> Mon 19 Oct.
    expect(nse.lastTradingDay(ist(2026, 10, 21, 9)), d('2026-10-19'));
    // Mon 5 Oct morning: Fri 2 Oct was Gandhi Jayanti -> Thu 1 Oct.
    expect(nse.lastTradingDay(ist(2026, 10, 5, 8)), d('2026-10-01'));
    // Independent of device time zone: input is a UTC instant.
    expect(nse.lastTradingDay(DateTime.utc(2026, 10, 13, 10, 31)), d('2026-10-13')); // 16:01 IST
  });

  test('market status labels', () {
    expect(nse.status(ist(2026, 10, 13, 8)).label, 'Closed · opens 9:15 AM');
    expect(nse.status(ist(2026, 10, 13, 9, 5)).phase, MarketPhase.preOpen);
    expect(nse.status(ist(2026, 10, 13, 11)).phase, MarketPhase.open);
    expect(nse.status(ist(2026, 10, 13, 15, 30)).label, 'Closed · opens Wed 14 Oct');
    expect(nse.status(ist(2026, 10, 20, 11)).label, 'Closed · Dussehra · opens Wed 21 Oct');
    expect(nse.status(ist(2026, 10, 17, 11)).label, 'Closed · Saturday · opens Mon 19 Oct');
  });

  test('upcoming weekday holidays only', () {
    final u = nse.upcoming(d('2026-10-13')).map((e) => fmtDay(e.$1)).toList();
    expect(u, ['2026-10-20', '2026-11-10', '2026-11-24', '2026-12-25']); // 8 Nov is a Sunday
  });

  test('SIP due on a holiday/weekend moves to next business day', () {
    const p = SipPlan(
        id: 1, instrumentId: 1, amountPaise: 1, dayOfMonth: 2, start: '2026-09-01', active: true);
    // 2 Oct 2026 is Gandhi Jayanti (Fri) -> Mon 5 Oct. Recorded on 5 Oct = matched.
    final s = sipStatus(p, [d('2026-09-02'), d('2026-10-05')], d('2026-10-20'));
    expect(s.missed, isEmpty);
    expect(s.recorded, 2);
    expect(s.nextDue, d('2026-11-02'));
    // 1 Aug 2026 is Saturday -> Mon 3 Aug.
    const p2 = SipPlan(
        id: 2, instrumentId: 1, amountPaise: 1, dayOfMonth: 1, start: '2026-08-01', active: true);
    expect(sipStatus(p2, [], d('2026-08-20')).missed, [d('2026-08-03')]);
  });
}
