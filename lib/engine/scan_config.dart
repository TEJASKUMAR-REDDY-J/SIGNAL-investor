// Weekly scan thresholds and weights. Edit freely; bump scanRuleVersion when you do.
// Universe: NIFTY 500 (includes the Midcap 150 and Smallcap 250).

const scanRuleVersion = 'scan/1 2026-10-14';

// Quality filters (a stock must pass all of them).
const minRoe = 0.12; // return on equity >= 12%
const maxDebtToEquityPct = 100.0; // Yahoo reports D/E in percent: 100 = 1x equity
const requirePositiveCashFlow = true; // operating or free cash flow > 0
const minMarketCapCr = 2000.0; // Rs crore, avoids illiquid names

// Momentum: 12-1 month return (skip the latest month, standard in research).
const momentumLookbackDays = 365;
const momentumSkipDays = 30;

// Score weights (sum to 1).
const wQuality = 0.4;
const wValue = 0.3;
const wMomentum = 0.3;

const topN = 5;

// Data freshness for the cache.
const fundamentalsMaxAgeDays = 30;
const pricesMaxAgeDays = 7;
