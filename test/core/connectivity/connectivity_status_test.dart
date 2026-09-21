import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';

void main() {
  group('ConnectivityStatus (HC-STATE-SEPARATION & SYNC-001)', () {
    test('online status exposes expected getters', () {
      const status = ConnectivityStatus.online;
      expect(status.isOnline, isTrue);
      expect(status.isOffline, isFalse);
    });

    test('offline status exposes expected getters', () {
      const status = ConnectivityStatus.offline;
      expect(status.isOnline, isFalse);
      expect(status.isOffline, isTrue);
    });

    test(
      'strictly isolates connectivity concerns from sync and operation status',
      () {
        // Must only define online and offline per HC-STATE-SEPARATION
        expect(ConnectivityStatus.values, [
          ConnectivityStatus.online,
          ConnectivityStatus.offline,
        ]);
      },
    );
  });
}
