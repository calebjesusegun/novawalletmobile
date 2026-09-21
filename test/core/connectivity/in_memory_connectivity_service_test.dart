import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';

void main() {
  group('InMemoryConnectivityService (SYNC-001 & ASM-009)', () {
    late InMemoryConnectivityService service;

    setUp(() {
      service = InMemoryConnectivityService();
    });

    tearDown(() {
      service.dispose();
    });

    test('defaults to online initial status', () async {
      expect(service.currentStatus, ConnectivityStatus.online);
      expect(await service.checkConnectivity(), ConnectivityStatus.online);
    });

    test('accepts custom initial status', () async {
      final offlineService = InMemoryConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
      addTearDown(offlineService.dispose);

      expect(offlineService.currentStatus, ConnectivityStatus.offline);
      expect(
        await offlineService.checkConnectivity(),
        ConnectivityStatus.offline,
      );
    });

    test('setStatus updates currentStatus and emits change event', () async {
      final emitted = <ConnectivityStatus>[];
      final subscription = service.onConnectivityChanged.listen(emitted.add);
      addTearDown(subscription.cancel);

      service.setStatus(ConnectivityStatus.offline);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentStatus, ConnectivityStatus.offline);
      expect(await service.checkConnectivity(), ConnectivityStatus.offline);
      expect(emitted, [ConnectivityStatus.offline]);

      service.setStatus(ConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(service.currentStatus, ConnectivityStatus.online);
      expect(emitted, [ConnectivityStatus.offline, ConnectivityStatus.online]);
    });

    test('setStatus does not re-emit unchanged status by default', () async {
      final emitted = <ConnectivityStatus>[];
      final subscription = service.onConnectivityChanged.listen(emitted.add);
      addTearDown(subscription.cancel);

      // Status is already online
      service.setStatus(ConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);

      // Explicitly forcing notification with notifyIfUnchanged: true
      service.setStatus(ConnectivityStatus.online, notifyIfUnchanged: true);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [ConnectivityStatus.online]);
    });

    test('toggle switches between online and offline', () async {
      final emitted = <ConnectivityStatus>[];
      final subscription = service.onConnectivityChanged.listen(emitted.add);
      addTearDown(subscription.cancel);

      service.toggle();
      await Future<void>.delayed(Duration.zero);
      expect(service.currentStatus, ConnectivityStatus.offline);

      service.toggle();
      await Future<void>.delayed(Duration.zero);
      expect(service.currentStatus, ConnectivityStatus.online);

      expect(emitted, [ConnectivityStatus.offline, ConnectivityStatus.online]);
    });

    test('stream supports multiple broadcast listeners', () async {
      final listenerA = <ConnectivityStatus>[];
      final listenerB = <ConnectivityStatus>[];

      final subA = service.onConnectivityChanged.listen(listenerA.add);
      final subB = service.onConnectivityChanged.listen(listenerB.add);
      addTearDown(subA.cancel);
      addTearDown(subB.cancel);

      service.setStatus(ConnectivityStatus.offline);
      await Future<void>.delayed(Duration.zero);

      expect(listenerA, [ConnectivityStatus.offline]);
      expect(listenerB, [ConnectivityStatus.offline]);
    });

    test(
      'dispose closes the stream and rejects subsequent status mutations',
      () {
        expect(service.isDisposed, isFalse);
        service.dispose();
        expect(service.isDisposed, isTrue);

        expect(
          () => service.setStatus(ConnectivityStatus.offline),
          throwsStateError,
        );
      },
    );
  });
}
