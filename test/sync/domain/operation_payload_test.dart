import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_type.dart';

void main() {
  group('SendMoneyPayload', () {
    test('creates valid payload and enforces integer kobo amount', () {
      final payload = SendMoneyPayload(
        recipientAccountNumber: '0123456789',
        recipientName: 'Jane Doe',
        bankName: 'NovaBank',
        amount: const Money.fromKobo(500000), // ₦5,000.00
        narration: 'Lunch money',
      );

      expect(payload.recipientAccountNumber, '0123456789');
      expect(payload.recipientName, 'Jane Doe');
      expect(payload.bankName, 'NovaBank');
      expect(payload.amount.kobo, 500000);
      expect(payload.amount.format(), '₦5,000.00');
      expect(payload.narration, 'Lunch money');
      expect(payload.type, OperationType.send);
    });

    test('validations reject empty recipient fields', () {
      expect(
        () => SendMoneyPayload(
          recipientAccountNumber: '',
          recipientName: 'Jane Doe',
          bankName: 'NovaBank',
          amount: const Money.fromKobo(1000),
        ),
        throwsArgumentError,
      );

      expect(
        () => SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: '   ',
          bankName: 'NovaBank',
          amount: const Money.fromKobo(1000),
        ),
        throwsArgumentError,
      );

      expect(
        () => SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Jane Doe',
          bankName: '',
          amount: const Money.fromKobo(1000),
        ),
        throwsArgumentError,
      );
    });

    test('validations reject non-positive amounts per HC-MONEY', () {
      expect(
        () => SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Jane Doe',
          bankName: 'NovaBank',
          amount: const Money.zero(),
        ),
        throwsA(isA<MoneyValidationException>()),
      );

      expect(
        () => SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Jane Doe',
          bankName: 'NovaBank',
          amount: const Money.fromKobo(-5000),
        ),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('serializes with schemaVersion and deserializes valid map', () {
      final original = SendMoneyPayload(
        recipientAccountNumber: '0123456789',
        recipientName: 'Jane Doe',
        bankName: 'NovaBank',
        amount: const Money.fromKobo(750000),
        narration: 'Project fee',
      );

      final map = original.toMap();
      expect(map['schemaVersion'], 1);
      expect(original.schemaVersion, 1);
      expect(map['amountKobo'], 750000);
      expect(map['recipientName'], 'Jane Doe');

      final deserialized = SendMoneyPayload.fromMap(map);
      expect(deserialized, original);
      expect(deserialized.hashCode, original.hashCode);
    });

    test(
      'fromMap throws PayloadFormatException on missing or invalid types',
      () {
        expect(
          () => SendMoneyPayload.fromMap(const {
            'recipientName': 'Jane',
            'bankName': 'Bank',
            'amountKobo': 1000,
          }),
          throwsA(isA<PayloadFormatException>()),
        );

        expect(
          () => SendMoneyPayload.fromMap(const {
            'recipientAccountNumber': 12345, // invalid type
            'recipientName': 'Jane',
            'bankName': 'Bank',
            'amountKobo': 1000,
          }),
          throwsA(isA<PayloadFormatException>()),
        );

        expect(
          () => SendMoneyPayload.fromMap(const {
            'recipientAccountNumber': '12345',
            'recipientName': 'Jane',
            'bankName': 'Bank',
            'amountKobo': 'invalid', // invalid type
          }),
          throwsA(isA<PayloadFormatException>()),
        );

        expect(
          () => SendMoneyPayload.fromMap(const {
            'recipientAccountNumber': '12345',
            'recipientName': 'Jane',
            'bankName': 'Bank',
            'amountKobo': 0, // non-positive
          }),
          throwsA(isA<PayloadFormatException>()),
        );
      },
    );
  });

  group('ContributionPayload', () {
    test('creates valid contribution payload', () {
      final payload = ContributionPayload(
        goalId: 'goal-123',
        goalName: 'Vacation Fund',
        amount: const Money.fromKobo(2500000), // ₦25,000.00
      );

      expect(payload.goalId, 'goal-123');
      expect(payload.goalName, 'Vacation Fund');
      expect(payload.amount.kobo, 2500000);
      expect(payload.type, OperationType.contribution);
    });

    test('validations reject empty goal fields', () {
      expect(
        () => ContributionPayload(
          goalId: '',
          goalName: 'Vacation Fund',
          amount: const Money.fromKobo(1000),
        ),
        throwsArgumentError,
      );

      expect(
        () => ContributionPayload(
          goalId: 'goal-123',
          goalName: '  ',
          amount: const Money.fromKobo(1000),
        ),
        throwsArgumentError,
      );
    });

    test('validations reject non-positive amounts', () {
      expect(
        () => ContributionPayload(
          goalId: 'goal-123',
          goalName: 'Vacation Fund',
          amount: const Money.zero(),
        ),
        throwsA(isA<MoneyValidationException>()),
      );

      expect(
        () => ContributionPayload(
          goalId: 'goal-123',
          goalName: 'Vacation Fund',
          amount: const Money.fromKobo(-1000),
        ),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('serializes with schemaVersion and deserializes valid map', () {
      final original = ContributionPayload(
        goalId: 'goal-999',
        goalName: 'Emergency Savings',
        amount: const Money.fromKobo(1000000),
      );

      final map = original.toMap();
      expect(map['schemaVersion'], 1);
      expect(original.schemaVersion, 1);
      expect(map['amountKobo'], 1000000);

      final deserialized = ContributionPayload.fromMap(map);
      expect(deserialized, original);
    });

    test(
      'fromMap throws PayloadFormatException on missing or invalid types',
      () {
        expect(
          () => ContributionPayload.fromMap(const {
            'goalName': 'Emergency',
            'amountKobo': 1000,
          }),
          throwsA(isA<PayloadFormatException>()),
        );

        expect(
          () => ContributionPayload.fromMap(const {
            'goalId': 123, // invalid type
            'goalName': 'Emergency',
            'amountKobo': 1000,
          }),
          throwsA(isA<PayloadFormatException>()),
        );

        expect(
          () => ContributionPayload.fromMap(const {
            'goalId': 'goal-1',
            'goalName': 'Emergency',
            'amountKobo': 0, // non-positive
          }),
          throwsA(isA<PayloadFormatException>()),
        );
      },
    );
  });

  group('Polymorphic OperationPayload.fromMap', () {
    test('deserializes SendMoneyPayload dynamically', () {
      final map = {
        'recipientAccountNumber': '123',
        'recipientName': 'Bob',
        'bankName': 'First Bank',
        'amountKobo': 50000,
      };

      final payload = OperationPayload.fromMap(OperationType.send, map);
      expect(payload, isA<SendMoneyPayload>());
      expect(payload.amount.kobo, 50000);
    });

    test('deserializes ContributionPayload dynamically', () {
      final map = {
        'goalId': 'g-1',
        'goalName': 'New Car',
        'amountKobo': 150000,
      };

      final payload = OperationPayload.fromMap(OperationType.contribution, map);
      expect(payload, isA<ContributionPayload>());
      expect(payload.amount.kobo, 150000);
    });
  });
}
