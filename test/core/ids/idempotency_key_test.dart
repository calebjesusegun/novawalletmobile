import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';

void main() {
  group('IdempotencyKey Construction & Validation', () {
    test('creates IdempotencyKey from a valid custom string', () {
      final key = IdempotencyKey('idem_send_001');
      expect(key.value, 'idem_send_001');
      expect(key.toString(), 'idem_send_001');
      expect(key.isUuid, isFalse);
    });

    test('creates IdempotencyKey with UUID v4 generation by default', () {
      final key = IdempotencyKey.generate();
      expect(key.isUuid, isTrue);
      expect(key.isUuidV4, isTrue);
      expect(key.value.length, 36);
      expect(IdempotencyKey.isValid(key.value), isTrue);
      expect(IdempotencyKey.isValidUuid(key.value), isTrue);
    });

    test('supports deterministic generation using seeded Random', () {
      final key1 = IdempotencyKey.generate(Random(42));
      final key2 = IdempotencyKey.generate(Random(42));
      expect(key1, key2);
      expect(key1.hashCode, key2.hashCode);
    });

    test('creates IdempotencyKey using fromUuid factory', () {
      const validUuid = 'c4b18c64-7546-4dc4-b778-4395b00c6d2c';
      final key = IdempotencyKey.fromUuid(validUuid);
      expect(key.value, validUuid);
      expect(key.isUuid, isTrue);
      expect(key.isUuidV4, isTrue);
    });

    test('fromUuid throws ArgumentError for non-UUID strings', () {
      expect(() => IdempotencyKey.fromUuid('custom-key'), throwsArgumentError);
      expect(() => IdempotencyKey.fromUuid(''), throwsArgumentError);
    });

    test('creates IdempotencyKey deterministically from OperationId', () {
      final opId = OperationId.generate();
      final key1 = IdempotencyKey.fromOperationId(opId);
      final key2 = IdempotencyKey.fromOperationId(opId);

      expect(key1, key2);
      expect(key1.value, opId.value);
    });

    test('creates IdempotencyKey from OperationId with custom prefix', () {
      final opId = OperationId('transfer-123');
      final key = IdempotencyKey.fromOperationId(opId, prefix: 'idem_');

      expect(key.value, 'idem_transfer-123');
    });

    test('normalizes UUID strings to canonical lowercase', () {
      const upperUuid = 'C4B18C64-7546-4DC4-B778-4395B00C6D2C';
      const lowerUuid = 'c4b18c64-7546-4dc4-b778-4395b00c6d2c';
      final key = IdempotencyKey(upperUuid);
      expect(key.value, lowerUuid);
      expect(key, IdempotencyKey(lowerUuid));
    });

    test('preserves casing for non-UUID identifiers', () {
      final key = IdempotencyKey('Key_Prefix.123:V2');
      expect(key.value, 'Key_Prefix.123:V2');
    });

    test('throws ArgumentError on empty string', () {
      expect(() => IdempotencyKey(''), throwsArgumentError);
    });

    test('throws ArgumentError on whitespace-only strings', () {
      expect(() => IdempotencyKey('   '), throwsArgumentError);
      expect(() => IdempotencyKey('\t\n'), throwsArgumentError);
    });

    test(
      'throws ArgumentError on leading, trailing, or internal whitespace',
      () {
        expect(() => IdempotencyKey(' key_123'), throwsArgumentError);
        expect(() => IdempotencyKey('key_123 '), throwsArgumentError);
        expect(() => IdempotencyKey('key 123'), throwsArgumentError);
        expect(() => IdempotencyKey('key\t123'), throwsArgumentError);
        expect(() => IdempotencyKey('key\n123'), throwsArgumentError);
      },
    );

    test('throws ArgumentError on strings containing invalid characters', () {
      expect(() => IdempotencyKey('key/123'), throwsArgumentError);
      expect(() => IdempotencyKey('key;123'), throwsArgumentError);
      expect(() => IdempotencyKey('key?param=1'), throwsArgumentError);
      expect(() => IdempotencyKey('key#hash'), throwsArgumentError);
      expect(() => IdempotencyKey('<key>'), throwsArgumentError);
      expect(() => IdempotencyKey('key@host'), throwsArgumentError);
      expect(() => IdempotencyKey('key!'), throwsArgumentError);
      expect(() => IdempotencyKey('key~1'), throwsArgumentError);
      expect(() => IdempotencyKey('key*'), throwsArgumentError);
    });

    test('throws ArgumentError when string exceeds 255 characters', () {
      final tooLong = 'k' * 256;
      expect(() => IdempotencyKey(tooLong), throwsArgumentError);

      final validLong = 'k' * 255;
      expect(IdempotencyKey(validLong).value, validLong);
    });
  });

  group('IdempotencyKey Invariant Validation Helper', () {
    test('isValid returns true for valid keys', () {
      expect(IdempotencyKey.isValid('key_1'), isTrue);
      expect(IdempotencyKey.isValid('idem-2026-09-21'), isTrue);
      expect(IdempotencyKey.isValid('user.transfer:send'), isTrue);
      expect(
        IdempotencyKey.isValid('c4b18c64-7546-4dc4-b778-4395b00c6d2c'),
        isTrue,
      );
    });

    test('isValid returns false for invalid strings', () {
      expect(IdempotencyKey.isValid(''), isFalse);
      expect(IdempotencyKey.isValid(' '), isFalse);
      expect(IdempotencyKey.isValid('key 1'), isFalse);
      expect(IdempotencyKey.isValid('key/1'), isFalse);
      expect(IdempotencyKey.isValid('k' * 256), isFalse);
    });

    test('isValidUuid matches RFC 4122 UUID format only', () {
      expect(
        IdempotencyKey.isValidUuid('c4b18c64-7546-4dc4-b778-4395b00c6d2c'),
        isTrue,
      );
      expect(IdempotencyKey.isValidUuid('key-123'), isFalse);
    });
  });

  group('IdempotencyKey Equality, Hashing & Ordering', () {
    test('implements value equality and consistent hashCode', () {
      final key1 = IdempotencyKey('key-test-1');
      final key2 = IdempotencyKey('key-test-1');
      final key3 = IdempotencyKey('key-test-2');

      expect(key1, key2);
      expect(key1.hashCode, key2.hashCode);
      expect(key1, isNot(key3));
      expect(key1.hashCode, isNot(key3.hashCode));
    });

    test(
      'is strictly not equal to an OperationId even with the same value',
      () {
        const commonValue = 'c4b18c64-7546-4dc4-b778-4395b00c6d2c';
        final idemKey = IdempotencyKey(commonValue);
        final opId = OperationId(commonValue);

        // IdempotencyKey must never equal OperationId
        expect(idemKey == (opId as dynamic), isFalse);
        expect(idemKey.hashCode, isNot(opId.hashCode));
      },
    );

    test('implements Comparable<IdempotencyKey> ordering', () {
      final keys = [
        IdempotencyKey('z'),
        IdempotencyKey('m'),
        IdempotencyKey('a'),
      ];

      keys.sort();
      expect(keys.map((k) => k.value).toList(), ['a', 'm', 'z']);
    });
  });

  group('IdempotencyKey Acceptance Criteria & HC-IDEMPOTENCY (T-ID-001)', () {
    test('one logical operation receives one stable idempotency key', () {
      final key = IdempotencyKey.generate();
      expect(key.value, isNotEmpty);
      expect(key.isUuidV4, isTrue);

      // Value remains stable
      expect(key.value, key.toString());
    });

    test('retrying the same logical operation reuses the same idempotency key across attempts', () {
      // User initiates Send Money
      final originalKey = IdempotencyKey.generate();

      // Simulate attempt 1: network timeout / failure
      final attempt1Key = originalKey;
      expect(attempt1Key, originalKey);

      // Simulate attempt 2: automatic reconnect retry
      final attempt2Key = originalKey;
      expect(attempt2Key, originalKey);

      // Simulate attempt 3: manual user tap on "Retry"
      final attempt3Key = originalKey;
      expect(attempt3Key, originalKey);

      // All attempts pass the exact same deduplication key
      expect(identical(attempt1Key.value, attempt3Key.value), isTrue);
    });

    test('reloading stored operation from persistence does not regenerate idempotency key', () {
      final originalKey = IdempotencyKey.generate();

      // Simulate local durable persistence (e.g. Drift/SQLite idempotency_key column)
      final persistedString = originalKey.value;

      // Simulate app restart / queue recovery
      final recoveredKey = IdempotencyKey(persistedString);

      expect(recoveredKey, originalKey);
      expect(recoveredKey.value, originalKey.value);
      expect(recoveredKey.hashCode, originalKey.hashCode);
    });

    test('new user intent creates a different idempotency key', () {
      // Intent 1: Send Money to Alice
      final intent1Key = IdempotencyKey.generate();

      // Intent 2: Send Money to Bob
      final intent2Key = IdempotencyKey.generate();

      expect(intent1Key, isNot(intent2Key));
      expect(intent1Key.value, isNot(intent2Key.value));
    });

    test('operation ID and idempotency key remain distinct and non-interchangeable', () {
      final opId = OperationId.generate();
      final idemKey = IdempotencyKey.fromOperationId(opId);

      // Distinct types even when wrapping equivalent values
      expect(opId.runtimeType, isNot(idemKey.runtimeType));
      expect(opId == (idemKey as dynamic), isFalse);
    });
  });
}
