import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';

void main() {
  group('Connectivity Providers (SYNC-001 & HC-STATE-SEPARATION)', () {
    late InMemoryConnectivityService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = InMemoryConnectivityService(
        initialStatus: ConnectivityStatus.online,
      );
      container = ProviderContainer(
        overrides: [connectivityServiceProvider.overrideWithValue(mockService)],
      );
    });

    tearDown(() {
      container.dispose();
      mockService.dispose();
    });

    test('connectivityStatusStreamProvider yields initial status and subsequent transitions', () async {
      final emitted = <ConnectivityStatus>[];

      final sub = container.listen<AsyncValue<ConnectivityStatus>>(
        connectivityStatusStreamProvider,
        (previous, next) {
          next.whenData(emitted.add);
        },
      );
      addTearDown(sub.close);

      // Wait for the initial stream emission
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [ConnectivityStatus.online]);
      expect(
        container.read(connectivityStatusProvider),
        ConnectivityStatus.online,
      );

      // Transition to offline
      mockService.setStatus(ConnectivityStatus.offline);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [ConnectivityStatus.online, ConnectivityStatus.offline]);
      expect(
        container.read(connectivityStatusProvider),
        ConnectivityStatus.offline,
      );

      // Transition back to online
      mockService.setStatus(ConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [
        ConnectivityStatus.online,
        ConnectivityStatus.offline,
        ConnectivityStatus.online,
      ]);
      expect(
        container.read(connectivityStatusProvider),
        ConnectivityStatus.online,
      );
    });
  });
}
