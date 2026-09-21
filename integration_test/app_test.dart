import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novawallet/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NovaWallet Integration Smoke Test', () {
    testWidgets('boots application and displays initial screen', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.text('Nova Wallet'), findsOneWidget);
    });
  });
}
