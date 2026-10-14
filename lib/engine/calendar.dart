import 'lots.dart';

// NSE trading holidays (Capital Market segment; the MF segment list is
// identical). Source: https://www.nseindia.com/api/holiday-master?type=trading
// lastVerified: 2026-10-13. Weekend-dated entries are kept for their names.
// Years not listed here fall back to weekends-only (see [MarketCalendar.knows]).
const nseHolidays2026 = {
  '2026-01-15': 'Municipal Corporation Election - Maharashtra',
  '2026-01-26': 'Republic Day',
  '2026-02-15': 'Mahashivratri',
  '2026-03-03': 'Holi',
  '2026-03-21': 'Id-Ul-Fitr (Ramadan Eid)',
  '2026-03-26': 'Shri Ram Navami',
  '2026-03-31': 'Shri Mahavir Jayanti',
  '2026-04-03': 'Good Friday',
  '2026-04-14': 'Dr. Baba Saheb Ambedkar Jayanti',
  '2026-05-01': 'Maharashtra Day',
  '2026-05-28': 'Bakri Id',
  '2026-06-26': 'Muharram',
  '2026-08-15': 'Independence Day',
  '2026-09-14': 'Ganesh Chaturthi',
  '2026-10-02': 'Mahatma Gandhi Jayanti',
  '2026-10-20': 'Dussehra',
  '2026-11-08': 'Diwali Laxmi Pujan (Muhurat trading session; timings per NSE circular)',
  '2026-11-10': 'Diwali-Balipratipada',
  '2026-11-24': 'Prakash Gurpurb Sri Guru Nanak Dev',
  '2026-12-25': 'Christmas',
};

const _ist = Duration(hours: 5, minutes: 30);

enum MarketPhase { preOpen, open, closed }

class MarketStatus {
  final MarketPhase phase;
  final String label; // e.g. "Open · closes 3:30 PM", "Closed · Dussehra"
  const MarketStatus(this.phase, this.label);
}

class MarketCalendar {
  /// 'YYYY-MM-DD' -> holiday name.
  final Map<String, String> holidays;
  const MarketCalendar([this.holidays = nseHolidays2026]);

  /// Years whose holiday list is loaded. Other years: weekends only.
  Set<int> get years => {for (final k in holidays.keys) int.parse(k.substring(0, 4))};
  bool knows(DateTime d) => years.contains(d.year);

  bool isWeekend(DateTime d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
  String? holidayName(DateTime d) => holidays[fmtDay(d)];
  bool isTradingDay(DateTime d) => !isWeekend(d) && holidayName(d) == null;

  /// Why the market is shut on [d], or null on a trading day.
  String? closedReason(DateTime d) =>
      holidayName(d) ?? (isWeekend(d) ? (d.weekday == DateTime.saturday ? 'Saturday' : 'Sunday') : null);

  DateTime onOrBefore(DateTime d) {
    while (!isTradingDay(d)) {
      d = DateTime.utc(d.year, d.month, d.day - 1);
    }
    return d;
  }

  DateTime onOrAfter(DateTime d) {
    while (!isTradingDay(d)) {
      d = DateTime.utc(d.year, d.month, d.day + 1);
    }
    return d;
  }

  /// Most recent trading-day close (16:00 IST, after the 15:30 close settles)
  /// at or before [nowUtc]. Prices fetched before this are stale.
  DateTime lastCloseUtc(DateTime nowUtc) {
    final ist = nowUtc.toUtc().add(_ist);
    var day = DateTime.utc(ist.year, ist.month, ist.day);
    if (!isTradingDay(day) || ist.hour < 16) day = onOrBefore(DateTime.utc(day.year, day.month, day.day - 1));
    return DateTime.utc(day.year, day.month, day.day, 16).subtract(_ist);
  }

  /// Last trading day whose NAV/close should exist at [nowUtc].
  DateTime lastTradingDay(DateTime nowUtc) {
    final c = lastCloseUtc(nowUtc).add(_ist);
    return DateTime.utc(c.year, c.month, c.day);
  }

  MarketStatus status(DateTime nowUtc) {
    final ist = nowUtc.toUtc().add(_ist);
    final day = DateTime.utc(ist.year, ist.month, ist.day);
    final why = closedReason(day);
    final next = onOrAfter(DateTime.utc(day.year, day.month, day.day + 1));
    String nextLabel() => 'opens ${_dow[next.weekday - 1]} ${next.day} ${_mon[next.month - 1]}';
    if (why != null) return MarketStatus(MarketPhase.closed, 'Closed · $why · ${nextLabel()}');
    final mins = ist.hour * 60 + ist.minute;
    if (mins < 9 * 60) return const MarketStatus(MarketPhase.closed, 'Closed · opens 9:15 AM');
    if (mins < 9 * 60 + 15) return const MarketStatus(MarketPhase.preOpen, 'Pre-open · opens 9:15 AM');
    if (mins < 15 * 60 + 30) return const MarketStatus(MarketPhase.open, 'Open · closes 3:30 PM');
    return MarketStatus(MarketPhase.closed, 'Closed · ${nextLabel()}');
  }

  /// Holidays on weekdays from [from] onwards (weekend-dated ones change nothing).
  List<(DateTime, String)> upcoming(DateTime from) => [
        for (final e in holidays.entries)
          if (!parseDay(e.key).isBefore(from) && !isWeekend(parseDay(e.key))) (parseDay(e.key), e.value),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
}

const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Active calendar: bundled list plus any holidays fetched from NSE.
var nse = const MarketCalendar();

void loadHolidays(Map<String, String> fetched) => nse = MarketCalendar({...nseHolidays2026, ...fetched});
