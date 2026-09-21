import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';

void main() {
  group('OperationId Construction & Validation', () {
    test('creates OperationId from a valid custom string', () {
      final id = OperationId('op_12345');
      expect(id.value, 'op_12345');
      expect(id.toString(), 'op_12345');
      expect(id.isUuid, isFalse);
    });

    test('creates OperationId with UUID v4 generation by default', () {
      final id = OperationId.generate();
      expect(id.isUuid, isTrue);
      expect(id.isUuidV4, isTrue);
      expect(id.value.length, 36);
      expect(OperationId.isValid(id.value), isTrue);
      expect(OperationId.isValidUuid(id.value), isTrue);
    });

    test('supports deterministic generation using seeded Random', () {
      final id1 = OperationId.generate(Random(999));
      final id2 = OperationId.generate(Random(999));
      expect(id1, id2);
      expect(id1.hashCode, id2.hashCode);
    });

    test('creates OperationId using fromUuid factory', () {
      const validUuid = 'c4b18c64-7546-4dc4-b778-4395b00c6d2c';
      final id = OperationId.fromUuid(validUuid);
      expect(id.value, validUuid);
      expect(id.isUuid, isTrue);
      expect(id.isUuidV4, isTrue);
    });

    test('fromUuid throws ArgumentError for non-UUID strings', () {
      expect(() => OperationId.fromUuid('custom-op-id'), throwsArgumentError);
      expect(() => OperationId.fromUuid(''), throwsArgumentError);
    });

    test('normalizes UUID strings to canonical lowercase', () {
      const upperUuid = 'C4B18C64-7546-4DC4-B778-4395B00C6D2C';
      const lowerUuid = 'c4b18c64-7546-4dc4-b778-4395b00c6d2c';
      final id = OperationId(upperUuid);
      expect(id.value, lowerUuid);
      expect(id, OperationId(lowerUuid));
    });

    test('preserves casing for non-UUID identifiers', () {
      final id = OperationId('Custom_Op_Id.123:V1');
      expect(id.value, 'Custom_Op_Id.123:V1');
    });

    test('throws ArgumentError on empty string', () {
      expect(() => OperationId(''), throwsArgumentError);
    });

    test('throws ArgumentError on whitespace-only strings', () {
      expect(() => OperationId('   '), throwsArgumentError);
      expect(() => OperationId('\t\n'), throwsArgumentError);
    });

    test(
      'throws ArgumentError on leading, trailing, or internal whitespace',
      () {
        expect(() => OperationId(' op_123'), throwsArgumentError);
        expect(() => OperationId('op_123 '), throwsArgumentError);
        expect(() => OperationId('op 123'), throwsArgumentError);
        expect(() => OperationId('op\t123'), throwsArgumentError);
        expect(() => OperationId('op\n123'), throwsArgumentError);
      },
    );

    test('throws ArgumentError on strings containing invalid characters', () {
      expect(() => OperationId('op/123'), throwsArgumentError);
      expect(() => OperationId('op;123'), throwsArgumentError);
      expect(() => OperationId('op?query=1'), throwsArgumentError);
      expect(() => OperationId('op#hash'), throwsArgumentError);
      expect(() => OperationId('<op>'), throwsArgumentError);
      expect(() => OperationId('op@novawallet'), throwsArgumentError);
      expect(() => OperationId('op!'), throwsArgumentError);
      expect(() => OperationId('op~1'), throwsArgumentError);
      expect(() => OperationId('op*'), throwsArgumentError);
    });

    test('throws ArgumentError when string exceeds 255 characters', () {
      final tooLong = 'a' * 256;
      expect(() => OperationId(tooLong), throwsArgumentError);

      final validLong = 'a' * 255;
      expect(OperationId(validLong).value, validLong);
    });
  });

  group('OperationId Invariant Validation Helper', () {
    test('isValid returns true for valid identifiers', () {
      expect(OperationId.isValid('op_1'), isTrue);
      expect(OperationId.isValid('txn-2026-09-21'), isTrue);
      expect(OperationId.isValid('user.transfer:send'), isTrue);
      expect(
        OperationId.isValid('c4b18c64-7546-4dc4-b778-4395b00c6d2c'),
        isTrue,
      );
    });

    test('isValid returns false for invalid strings', () {
      expect(OperationId.isValid(''), isFalse);
      expect(OperationId.isValid(' '), isFalse);
      expect(OperationId.isValid('op 1'), isFalse);
      expect(OperationId.isValid('op/1'), isFalse);
      expect(OperationId.isValid('a' * 256), isFalse);
    });

    test('isValidUuid matches RFC 4122 UUID format only', () {
      expect(
        OperationId.isValidUuid('c4b18c64-7546-4dc4-b778-4395b00c6d2c'),
        isTrue,
      );
      expect(OperationId.isValidUuid('op-123'), isFalse);
    });
  });

  group('OperationId Equality, Hashing & Ordering', () {
    test('implements value equality and consistent hashCode', () {
      final id1 = OperationId('op-test-1');
      final id2 = OperationId('op-test-1');
      final id3 = OperationId('op-test-2');

      expect(id1, id2);
      expect(id1.hashCode, id2.hashCode);
      expect(id1, isNot(id3));
      expect(id1.hashCode, isNot(id3.hashCode));
    });

    test(
      'is strictly not equal to an IdempotencyKey even with the same value',
      () {
        const commonValue = 'c4b18c64-7546-4dc4-b778-4395b00c6d2c';
        final opId = OperationId(commonValue);
        final idemKey = IdempotencyKey(commonValue);

        // OperationId must never equal IdempotencyKey
        expect(opId == (idemKey as dynamic), isFalse);
        expect(opId.hashCode, isNot(idemKey.hashCode));
      },
    );

    test('implements Comparable<OperationId> ordering', () {
      final ids = [OperationId('c'), OperationId('a'), OperationId('b')];

      ids.sort();
      expect(ids.map((id) => id.value).toList(), ['a', 'b', 'c']);
    });
  });

  group('OperationId Acceptance Criteria (T-ID-001)', () {
    test('one logical operation receives one stable local operation ID', () {
      final opId = OperationId.generate();
      expect(opId.value, isNotEmpty);
      expect(opId.isUuidV4, isTrue);

      // Stable across references
      final ref = opId;
      expect(ref, opId);
    });

    test('retrying/reloading the same stored operation does not regenerate identity', () {
      final originalOpId = OperationId.generate();

      // Simulate persistence serialization (e.g. into Drift/SQLite column)
      final serialized = originalOpId.value;

      // Simulate app restart / reload from durable storage
      final reloadedOpId = OperationId(serialized);

      expect(reloadedOpId, originalOpId);
      expect(reloadedOpId.value, originalOpId.value);
      expect(reloadedOpId.hashCode, originalOpId.hashCode);
    });

    test('new user intent creates a different identity', () {
      final op1 = OperationId.generate();
      final op2 = OperationId.generate();

      expect(op1, isNot(op2));
      expect(op1.value, isNot(op2.value));
    });
  });
}
