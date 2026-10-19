# SIGNAL Investor

A private, local-first investing app for Android where **three autonomous AI agents paper-trade the NIFTY 500 on their own**, every market day, right on the phone. No backend, no accounts, no broker connection: everything runs on the device in an encrypted database.

> Track. Rule. Alert. Don't predict.

---

## Highlights

### Autonomous paper-trading agents

Three agents each manage ₹25 lakh of simulated money in NIFTY 500 stocks, with different styles:

| Agent | Style | Exits |
|---|---|---|
| **Daily** | Short-term: fresh good news and strong recent moves | +5%, −3%, bad news, or after a week |
| **Weekly** | Swing: 1-month leaders, rebalanced on the first trading day of each week | +12%, −7%, or when the trend turns |
| **Monthly** | Long-term compounder: quality and growth leaders, bought a little every day like a SIP | only when the case breaks |

Every market day each agent runs an agentic loop:

1. **Rules shortlist**: a scoring engine ranks the whole NIFTY 500 on quality, growth, value, momentum, news and chart technicals, and proposes buys and exits.
2. **LLM with tools**: an LLM (`gpt-oss-120b` via Groq function calling) studies the shortlist by calling tools, up to 5 rounds:
   `get_portfolio` · `get_market_regime` · `get_technicals` · `get_fundamentals` · `get_news` · `compare` · `get_track_record`
3. **Debate and decide**: it writes a bull case and a bear case, then calls `submit_decision` with structured buys and sells.
4. **Hard limits in code**: whatever the model says, the code enforces them: ₹50,000 per stock per day, ₹4 lakh of new money per month (spread across the month), max 3 holdings per industry, whole shares, 0.1% costs, and stop-losses that always fire.
5. **Reflection memory**: each week every agent reviews its closed trades and writes short lessons, which it reads before future decisions.

**Risk manager**
- **Market regime:** NIFTY vs its 200-day average, India VIX, and the share of stocks above their 50-day average. In a weak market the traders spend less.
- **Volatility-scaled position sizing.**
- **Drawdown brake:** half size after an 8% fall from the agent's peak value; no new buys past 15%.
- **Always invests:** if the AI is too cautious, the agent tops up from the rule picks.

**Full transparency**
- **Scorecard:** return, alpha vs NIFTY, Sharpe ratio, max drawdown, win rate.
- **Race chart:** the three agents against NIFTY.
- **Every run is logged:** what was bought or sold and why, the bull and bear cases, and the number of tool calls.
- **Owner notes:** you can leave notes the agents read.

### Your own portfolio
- Record stocks and mutual funds. Prices and fund NAVs fill in automatically.
- Gains, XIRR, FIFO tax lots, and capital gains tax for the year (FY 2026-27 rules).
- A sell flow that shows the tax saved by waiting for long-term status.
- SIP plans, goals, alerts, watchlist, and a "hide amounts" mode.

### News as points
- Business news and NSE filings for the companies you hold or follow are read three times a day.
- An LLM labels each headline +1 or −1 for the company it is about, with a reason.
- Names that several listed companies share are matched carefully, so news isn't credited to the wrong company.
- A notification digest summarises it all.

### Research lab
- **Advisor:** ranks NIFTY 500 stocks (quality filters, then quality / growth / value / momentum) and mutual funds by category (3- and 5-year growth, worst fall), with reasons.
- **Ask SIGNAL:** an AI guide that looks things up itself (technicals, fundamentals, news, fund returns, the agents' books) and explains them in plain words. Optional web search.
- **Sandbox:** paper trading for you, at real prices.
- **Time machine:** what a SIP or lump sum would have done, on real history.

### Runs in the background
- An hourly Android WorkManager job trades for the agents (from 09:45 IST on market days) and posts news and trade notifications, even with the app closed.
- A database lease stops the app and the background job from ever running the agents twice.
- The app asks for an exemption from battery optimisation, so the job isn't killed.

---

## Tech stack

| Area | Choice |
|---|---|
| App | Flutter (Android), Dart 3 |
| Storage | drift + SQLite3MultipleCiphers (encrypted at rest), keys in Android Keystore via `flutter_secure_storage` |
| Unlock | `local_auth`: the phone's fingerprint, face or screen lock |
| Background | `workmanager` (hourly periodic task), `flutter_local_notifications` |
| Charts | `fl_chart` |
| LLM | Groq API, `openai/gpt-oss-120b`, function calling |
| Market data | Public sources: Yahoo Finance (quotes, history, fundamentals), NSE (NIFTY 500 list, filings, holidays), AMFI and mfapi.in (mutual fund NAVs), RSS news |

## Project layout

```
lib/
  engine/     pure logic: agents, indicators (RSI, MACD, Bollinger, ATR, ...), regime,
              scoring, fund ranking, tax, lots, XIRR, money (integer paise)
  pipeline/   agents_run (the agentic loop), scan, refresh, background job, news feeds
  sources/    HTTP clients: Groq, Yahoo, NSE, AMFI, mfapi, RSS (rate limits, backoff)
  db/         drift schema for the market DB and the profile DB, encrypted open
  ui/         screens: Agents, Home, Holdings, Plan, Lab, Ask, Advisor, Settings
test/         unit, widget and end-to-end tests (+ live checks behind LIVE=1)
```

## Getting started

Requirements: Flutter (stable), Android SDK, JDK 17+.

```bash
git clone https://github.com/TEJASKUMAR-REDDY-J/SIGNAL-investor.git
cd SIGNAL-investor
flutter pub get
cp .env.example .env        # then paste your Groq API key (https://console.groq.com/keys)
flutter run --dart-define-from-file=.env
```

Release build:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=.env --target-platform android-arm64,android-x64
```

Without a Groq key the app still works: the agents trade on the rules alone, and the AI features ask for a key in Settings.

> The key in `.env` is compiled into the APK and can be extracted from it. Keep builds that contain your key private.

## Tests

```bash
flutter test                                          # unit, widget and end-to-end tests
LIVE=1 flutter test test/live_full_test.dart          # live: fresh install -> full NIFTY 500 scan -> all three agents trade
LIVE=1 flutter test test/live_agents_test.dart        # live: AI tool loop and Ask SIGNAL
```

The end-to-end tests drive the whole agent pipeline with mocked HTTP: data, rules, the LLM tool loop, hard limits, logging, once-per-day runs, duplicate-run locking and recovery from rate limits.

## Privacy and security

- **Local-first:** no server, no sign-up, no analytics. Data never leaves the phone except for public market-data requests and, if enabled, questions sent to the LLM.
- **Encrypted:** both databases are encrypted; keys live in the Android Keystore; unlocked with the phone's own biometrics.
- **No sensitive identifiers:** there are no fields for PAN, Aadhaar, bank, demat or broker details.
- **Hardened app:** `FLAG_SECURE` (no screenshots or recents preview), `allowBackup=false`, HTTPS only, no logging of responses or holdings.
- **Exact money:** amounts are stored as integer paise, never floating point.

## Disclaimer

SIGNAL Investor is a personal decision aid and a learning tool, **not investment, tax or legal advice**, and its authors are not SEBI-registered advisers. The agents trade **paper money only**; the app never places real orders and never connects to a broker. Market data comes from unofficial public sources and can be late or wrong. Past simulated results do not predict real returns.
