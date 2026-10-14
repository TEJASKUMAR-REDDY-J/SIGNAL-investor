import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/pipeline/background.dart';
import 'package:signal_investor/sources/net.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('daily job finishes when every source is down', () async {
    FlutterSecureStorage.setMockInitialValues({'tracked_ids': '[1,2]'});
    final m = MarketDb(NativeDatabase.memory());
    final net = Net(client: MockClient((r) async => http.Response('', 503)));
    final line = await runDaily(market: m, net: net, nowUtc: DateTime.utc(2026, 10, 14, 10)).timeout(const Duration(seconds: 60));
    expect(line, isNull);
    await m.close();
  });
}
