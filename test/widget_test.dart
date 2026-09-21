import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/app/app.dart';

void main() {
  testWidgets('NovaWalletApp launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NovaWalletApp()));

    expect(find.byType(NovaWalletApp), findsOneWidget);
    expect(find.byType(NovaWalletShell), findsOneWidget);
  });
}
