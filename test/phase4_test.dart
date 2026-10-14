import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/alerts.dart';
import 'package:signal_investor/sources/groq.dart';
import 'package:signal_investor/sources/rss.dart';

void main() {
  group('RSS and GDELT', () {
    test('parses real Mint RSS items with UTC times', () {
      final items = parseRss(File('test/fixtures/mint_rss.xml').readAsStringSync(), 'Mint');
      expect(items, hasLength(3));
      for (final h in items) {
        expect(h.url, startsWith('https://'));
        expect(h.title, isNot(contains('<![CDATA[')));
        expect(h.publishedUtc.isUtc, isTrue);
      }
    });
    test('RFC 822 offsets', () {
      expect(parseRfc822('Tue, 14 Oct 2026 09:15:00 +0530'), DateTime.utc(2026, 10, 14, 3, 45));
      expect(parseRfc822('Tue, 14 Oct 2026 09:15:00 GMT'), DateTime.utc(2026, 10, 14, 9, 15));
      expect(parseRfc822('Tue, 14 Oct 2026 09:15:00 IST'), DateTime.utc(2026, 10, 14, 3, 45));
      expect(parseRfc822('garbage'), isNull);
    });
    test('GDELT artlist', () {
      final r = parseGdelt('{"articles":[{"url":"https://a.test/x","title":"TCS wins deal","seendate":"20261014T051500Z","domain":"a.test"},'
          '{"url":"http://insecure.test","title":"x","seendate":"20261014T051500Z"}]}');
      expect(r.single.publishedUtc, DateTime.utc(2026, 10, 14, 5, 15));
      expect(parseGdelt('{}'), isEmpty);
    });
  });

  group('dedupe and matching', () {
    test('same story twice: same normalised title; url hash stable', () {
      expect(normTitle('TCS Q2: profit beats estimates!'), normTitle('TCS Q2 profit beats estimates'));
      expect(urlHash('https://x.test/a'), urlHash(' https://x.test/a '));
      expect(urlHash('https://x.test/a'), isNot(urlHash('https://x.test/b')));
      expect(urlHash('https://x.test/a'), hasLength(16));
    });
    test('company terms match whole words only', () {
      final t = matchTerms('Tata Consultancy Services Ltd.', 'TCS', '');
      expect(t, contains('tata consultancy'));
      expect(mentions('Tata Consultancy bags 2 bn deal', t), isTrue);
      final infy = matchTerms('Infosys Limited', 'INFY', 'infosys');
      expect(mentions('Infosys shares rise after results', infy), isTrue);
      expect(mentions('Infra stocks rally', infy), isFalse);
      final hdfc = matchTerms('HDFC Bank Ltd', 'HDFCBANK', '');
      expect(mentions('HDFC Bank Q2 results', hdfc), isTrue);
      expect(mentions('HDFC Life premium growth', hdfc), isFalse);
    });
  });

  group('Groq output validation', () {
    final inputs = [TagInput('https://n.test/1', 'TCS Q2 beats', 'Mint', DateTime.utc(2026, 10, 14), 'Tata Consultancy Services')];
    test('valid item kept', () {
      final t = validateTags(
          '{"items":[{"company":"Tata Consultancy Services","label":"positive","confidence":0.8,"reason":"Profit beat","url":"https://n.test/1"}]}',
          inputs);
      expect(t.single.label, 'positive');
    });
    test('invalid output is dropped', () {
      String item(String f) => '{"items":[{$f}]}';
      const ok = '"company":"Tata Consultancy Services","label":"positive","confidence":0.8,"reason":"Profit beat","url":"https://n.test/1"';
      expect(validateTags('not json', inputs), isEmpty);
      expect(validateTags('{"items":"x"}', inputs), isEmpty);
      expect(validateTags(item(ok.replaceFirst('positive', 'bullish')), inputs), isEmpty); // bad label
      expect(validateTags(item(ok.replaceFirst('0.8', '1.7')), inputs), isEmpty); // confidence out of range
      expect(validateTags(item(ok.replaceFirst('https://n.test/1', 'https://evil.test')), inputs), isEmpty); // url not echoed
      expect(validateTags(item(ok.replaceFirst('Tata Consultancy Services', 'Infosys')), inputs), isEmpty); // wrong company
      expect(validateTags(item(ok.replaceFirst('Profit beat', List.filled(21, 'word').join(' '))), inputs), isEmpty); // >20 words
      expect(validateTags(item(ok.replaceFirst('"confidence":0.8', '"confidence":"high"')), inputs), isEmpty);
    });
    test('quoted .env keys are cleaned', () {
      expect(cleanKey('"gsk_abc"'), 'gsk_abc');
      expect(cleanKey(" 'gsk_abc' "), 'gsk_abc');
      expect(cleanKey(''), isNull);
    });
  });

  group('assistant output', () {
    test('ground truth carries the app tax constants', () {
      expect(groundTruth, contains('flat 20%'));
      expect(groundTruth, contains('12.5%'));
      expect(groundTruth, contains('1,25,000'));
      expect(groundTruth, contains('MORE than 12 months'));
    });
    test('markdown is flattened to plain text', () {
      final t = plainText('## Heading\n**Bold** text\n| A | B |\n|---|---|\n| 1 | 2 |\n\n\n\nEnd &gt; x');
      expect(t, isNot(contains('**')));
      expect(t, isNot(contains('#')));
      expect(t, isNot(contains('|')));
      expect(t, contains('Bold text'));
      expect(t, contains('End > x'));
    });
  });

  group('alerts fire only per section 7', () {
    final now = DateTime.utc(2026, 10, 14, 6);
    NewsItem n(String pub, String label, int hoursAgo, [int inst = 1]) => NewsItem(
        urlHash: '$pub$hoursAgo$inst', url: 'https://x.test', title: 't', publisher: pub,
        publishedAt: now.subtract(Duration(hours: hoursAgo)), instrumentId: inst, label: label);
    Filing f(String subject, String date, [int inst = 1]) =>
        Filing(id: 1, instrumentId: inst, date: date, category: subject, subject: '', url: '');

    test('negative from 2+ publishers within 48h', () {
      expect(alertsFor(held: {1}, news: [n('Mint', 'negative', 5)], filings: [], nowUtc: now), isEmpty);
      expect(alertsFor(held: {1}, news: [n('Mint', 'negative', 5), n('Mint', 'negative', 6)], filings: [], nowUtc: now), isEmpty);
      expect(alertsFor(held: {1}, news: [n('Mint', 'negative', 5), n('ET', 'negative', 6)], filings: [], nowUtc: now), hasLength(1));
      expect(alertsFor(held: {1}, news: [n('Mint', 'negative', 5), n('ET', 'negative', 60)], filings: [], nowUtc: now), isEmpty);
      expect(alertsFor(held: {1}, news: [n('Mint', 'negative', 5), n('ET', 'positive', 6)], filings: [], nowUtc: now), isEmpty);
      expect(alertsFor(held: {2}, news: [n('Mint', 'negative', 5), n('ET', 'negative', 6)], filings: [], nowUtc: now), isEmpty);
    });
    test('alert-class filings only', () {
      expect(filingCategory('Change in Statutory Auditor'), 'auditor');
      expect(filingCategory('Financial Results for Q2'), 'results');
      expect(filingCategory('Creation of pledge'), 'pledge');
      expect(filingCategory('Copy of Newspaper Publication'), isNull);
      expect(alertsFor(held: {1}, news: [], filings: [f('Copy of Newspaper Publication', '2026-10-13')], nowUtc: now), isEmpty);
      expect(alertsFor(held: {1}, news: [], filings: [f('Credit Rating', '2026-10-13')], nowUtc: now).single.kind, 'filing');
      expect(alertsFor(held: {1}, news: [], filings: [f('Credit Rating', '2026-09-01')], nowUtc: now), isEmpty);
    });
  });
}
