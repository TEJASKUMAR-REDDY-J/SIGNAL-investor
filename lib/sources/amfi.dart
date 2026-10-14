import 'net.dart';

// portal.amfiindia.com/spages/NAVAll.txt, probed 2026-10-14 (www.amfiindia.com 302s here):
// ~1.5 MB, every open scheme's latest NAV. Section lines "Open Ended Schemes(<category>)",
// then AMC name lines, then rows "code;isinGrowth;isinReinv;name;plan;option;nav;dd-Mon-yyyy".
// Plan is "Direct Plan" / "Regular Plan" (legacy rows leave plan and option empty).

class FundRow {
  final String code;
  final String name;
  final String category; // e.g. "Flexi Cap Fund"
  final int navE4;
  const FundRow(this.code, this.name, this.category, this.navE4);
}

/// Equity categories the advisor ranks (AMFI names after normalising).
const fundCategories = [
  'Large Cap Fund',
  'Flexi Cap Fund',
  'Large & Mid Cap Fund',
  'Mid Cap Fund',
  'Small Cap Fund',
  'Multi Cap Fund',
  'ELSS',
  'Focused Fund',
  'Value Fund',
];

String _category(String header) {
  final m = RegExp(r'\((.*)\)\s*$').firstMatch(header);
  var c = m?.group(1) ?? header;
  c = c.replaceFirst(RegExp(r'^Equity Schemes? - '), '');
  if (c.startsWith('ELSS')) c = 'ELSS';
  return c.trim();
}

final _growth = RegExp(r'^(direct )?growth( option)*$');

/// Direct-plan growth options in [fundCategories] only.
List<FundRow> parseNavAll(String body) {
  final out = <FundRow>[];
  String? cat;
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('Open Ended') || line.startsWith('Close Ended') || line.startsWith('Interval')) {
      final c = line.startsWith('Open Ended') ? _category(line) : null;
      cat = fundCategories.contains(c) ? c : null;
      continue;
    }
    if (cat == null) continue;
    final p = line.split(';');
    if (p.length < 8 || !RegExp(r'^\d{3,7}$').hasMatch(p[0].trim())) continue;
    final opt = p[5].trim().toLowerCase().replaceAll(RegExp(r'[()]'), '');
    if (p[4].trim() != 'Direct Plan' || !_growth.hasMatch(opt)) continue;
    final nav = decimalE4(p[6].trim());
    if (nav == null || nav <= 0) continue;
    out.add(FundRow(p[0].trim(), p[3].trim(), cat, nav));
  }
  return out;
}

Future<List<FundRow>> amfiFunds(Net n) async =>
    parseNavAll((await n.get('amfi', Uri.parse('https://portal.amfiindia.com/spages/NAVAll.txt'))).body);
