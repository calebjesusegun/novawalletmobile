import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/uuid.dart';

void main() {
  group('Uuid.v4 Generation', () {
    test('generates valid RFC 4122 version 4 UUID strings', () {
      final id = Uuid.v4();
      expect(Uuid.isValid(id), isTrue);
      expect(Uuid.isValidV4(id), isTrue);
      expect(Uuid.isGeneralUuid(id), isTrue);
      expect(id.length, 36);

      // Verify hyphen positions
      expect(id[8], '-');
      expect(id[13], '-');
      expect(id[18], '-');
      expect(id[23], '-');

      // Verify version nibble is '4'
      expect(id[14], '4');

      // Verify variant nibble is '8', '9', 'a', or 'b'
      final variantChar = id[19].toLowerCase();
      expect(['8', '9', 'a', 'b'].contains(variantChar), isTrue);
    });

    test('generates unique UUIDs on repeated calls', () {
      final ids = List.generate(500, (_) => Uuid.v4());
      final uniqueSet = ids.toSet();
      expect(uniqueSet.length, 500);
    });

    test('generates deterministic UUIDs when seeded Random is provided', () {
      final id1 = Uuid.v4(Random(12345));
      final id2 = Uuid.v4(Random(12345));
      expect(id1, id2);
      expect(Uuid.isValidV4(id1), isTrue);
    });
  });

  group('Uuid Validation', () {
    test('validates valid RFC 4122 UUIDs (v1 through v5)', () {
      // v1
      expect(Uuid.isValid('6ba7b810-9dad-11d1-80b4-00c04fd430c8'), isTrue);
      expect(Uuid.isValidV4('6ba7b810-9dad-11d1-80b4-00c04fd430c8'), isFalse);

      // v4
      expect(Uuid.isValid('c4b18c64-7546-4dc4-b778-4395b00c6d2c'), isTrue);
      expect(Uuid.isValidV4('c4b18c64-7546-4dc4-b778-4395b00c6d2c'), isTrue);

      // v5
      expect(Uuid.isValid('886313e1-3b8a-5372-9b90-0c9aee199e5d'), isTrue);
      expect(Uuid.isValidV4('886313e1-3b8a-5372-9b90-0c9aee199e5d'), isFalse);

      // uppercase v4
      expect(Uuid.isValid('C4B18C64-7546-4DC4-B778-4395B00C6D2C'), isTrue);
      expect(Uuid.isValidV4('C4B18C64-7546-4DC4-B778-4395B00C6D2C'), isTrue);
    });

    test('isGeneralUuid recognizes nil UUID and any 8-4-4-4-12 hex UUID', () {
      const nilUuid = '00000000-0000-0000-0000-000000000000';
      expect(Uuid.isGeneralUuid(nilUuid), isTrue);
      expect(Uuid.isValid(nilUuid), isFalse); // nil is version 0
    });

    test('rejects malformed UUID strings', () {
      expect(Uuid.isValid(''), isFalse);
      expect(Uuid.isValid('not-a-uuid'), isFalse);
      expect(
        Uuid.isValid('c4b18c64-7546-4dc4-b778-4395b00c6d2'),
        isFalse,
      ); // too short
      expect(
        Uuid.isValid('c4b18c64-7546-4dc4-b778-4395b00c6d2cc'),
        isFalse,
      ); // too long
      expect(
        Uuid.isValid('c4b18c6475464dc4b7784395b00c6d2c'),
        isFalse,
      ); // missing hyphens
      expect(
        Uuid.isValid('c4b18c64-7546-4dc4-b778_4395b00c6d2c'),
        isFalse,
      ); // wrong separator
      expect(
        Uuid.isValid('c4b18c64-7546-4dc4-b778-4395b00c6d2z'),
        isFalse,
      ); // non-hex character
    });
  });
}
