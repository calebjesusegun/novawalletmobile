import 'package:integration_test/integration_test.dart';

import '../test/app/app_offline_restart_sync_test.dart' as app_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Runs the complete offline queue -> restart -> reconnect -> exactly-once effect integration test
  app_test.main();
}
