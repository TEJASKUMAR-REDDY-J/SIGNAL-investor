import 'lots.dart';
import 'money.dart';

// Tax constants for listed equity shares and equity-oriented mutual funds.
// lastVerified: 2026-10-12 for FY / Tax Year 2026-27 (Budget 1 Feb 2026 left
// these unchanged; Income-tax Act 2025 in force from 1 Apr 2026).
// Out of scope: surcharge, debt funds, grandfathering (pre-31 Jan 2018),
// loss carry-forward, rebate u/s 87A, rounding of tax to nearest Rs 10.
const stcgBps = 2000; // 20%
const ltcgBps = 1250; // 12.5%
const cessBps = 400; // 4% on tax
const ltcgExemptionPaise = 12500000; // Rs 1,25,000 per person per FY

/// Financial year start year: 2026-04-01..2027-03-31 -> 2026.
int fyOf(DateTime d) => d.month >= 4 ? d.year : d.year - 1;

class Tax {
  final int stcgPaise; // net taxable STCG after set-off
  final int ltcgPaise; // net LTCG after set-off, before exemption
  final int exemptionUsedPaise;
  final int taxPaise; // incl. cess
  const Tax(this.stcgPaise, this.ltcgPaise, this.exemptionUsedPaise,
      this.taxPaise);
  int get exemptionLeftPaise => ltcgExemptionPaise - exemptionUsedPaise;
}

/// Tax for one FY's gross gains. ST losses offset STCG then LTCG;
/// LT losses offset only LTCG.
Tax taxFor({required int stGainPaise, required int ltGainPaise}) {
  var st = stGainPaise, lt = ltGainPaise;
  if (st < 0) {
    lt += st;
    st = 0;
  }
  if (lt < 0) lt = 0;
  final exempt = lt < ltcgExemptionPaise ? lt : ltcgExemptionPaise;
  final base = mulDiv(st, stcgBps, 10000) + mulDiv(lt - exempt, ltcgBps, 10000);
  return Tax(st, lt, exempt, base + mulDiv(base, cessBps, 10000));
}

/// Realized ST and LT gains in FY [fy] across all instruments of a profile.
({int st, int lt}) fyGains(Iterable<Realized> realized, int fy) {
  var st = 0, lt = 0;
  for (final r in realized) {
    if (fyOf(r.sellDate) != fy) continue;
    if (r.longTerm) {
      lt += r.gainPaise;
    } else {
      st += r.gainPaise;
    }
  }
  return (st: st, lt: lt);
}

/// Tax already due on this FY's realized sales (all instruments).
Tax fyTax(Iterable<Realized> realized, int fy) {
  final g = fyGains(realized, fy);
  return taxFor(stGainPaise: g.st, ltGainPaise: g.lt);
}

class SaleEstimate {
  final List<Realized> slices;
  final int extraTaxPaise; // incremental tax this sale adds to the FY
  final int proceedsPaise;
  const SaleEstimate(this.slices, this.extraTaxPaise, this.proceedsPaise);
  int get gainPaise => slices.fold(0, (a, r) => a + r.gainPaise);
}

/// Tax on a hypothetical sale of [units4] at [price4] on [date] from FIFO
/// [lots], on top of [realizedAll] (every realized slice in the profile).
SaleEstimate estimateSale({
  required List<Lot> lots,
  required int units4,
  required int price4,
  required DateTime date,
  required Iterable<Realized> realizedAll,
  int feesPaise = 0,
}) {
  final sale = sellFifo([...lots], units4, price4, feesPaise, date);
  final fy = fyOf(date);
  final before = fyTax(realizedAll, fy).taxPaise;
  final after = fyTax([...realizedAll, ...sale], fy).taxPaise;
  return SaleEstimate(
      sale, after - before, sale.fold(0, (a, r) => a + r.proceedsPaise));
}
