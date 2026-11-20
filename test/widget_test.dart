import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:volugreen_mobile/core/api_client.dart';
import 'package:volugreen_mobile/core/auth_provider.dart';
import 'package:volugreen_mobile/main.dart';

void main() {
  testWidgets('tanpa sesi, aplikasi menampilkan layar masuk', (tester) async {
    final api = ApiClient();
    final auth = AuthProvider(api)..ready = true;
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: const VoluGreenApp(),
    ));
    expect(find.text('VoluGreen'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
  });
}
