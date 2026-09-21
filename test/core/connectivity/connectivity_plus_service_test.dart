import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';

void main() {
  group('ConnectivityPlusService.mapResults (SYNC-001)', () {
    test('empty list maps to offline', () {
      expect(
        ConnectivityPlusService.mapResults([]),
        ConnectivityStatus.offline,
      );
    });

    test('list containing only none maps to offline', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.none]),
        ConnectivityStatus.offline,
      );
    });

    test('list containing only bluetooth maps to offline', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.bluetooth]),
        ConnectivityStatus.offline,
      );
    });

    test('wifi maps to online', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.wifi]),
        ConnectivityStatus.online,
      );
    });

    test('mobile maps to online', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.mobile]),
        ConnectivityStatus.online,
      );
    });

    test('ethernet maps to online', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.ethernet]),
        ConnectivityStatus.online,
      );
    });

    test('vpn maps to online', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.vpn]),
        ConnectivityStatus.online,
      );
    });

    test('other maps to online', () {
      expect(
        ConnectivityPlusService.mapResults([ConnectivityResult.other]),
        ConnectivityStatus.online,
      );
    });

    test('combination with wifi and vpn maps to online', () {
      expect(
        ConnectivityPlusService.mapResults([
          ConnectivityResult.wifi,
          ConnectivityResult.vpn,
        ]),
        ConnectivityStatus.online,
      );
    });

    test(
      'combination containing none but also active interface maps to online',
      () {
        expect(
          ConnectivityPlusService.mapResults([
            ConnectivityResult.none,
            ConnectivityResult.wifi,
          ]),
          ConnectivityStatus.online,
        );
      },
    );
  });
}
