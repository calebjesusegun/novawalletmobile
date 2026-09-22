import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/features/send_money/data/fake_recipient_directory.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/controllers/recipient_entry_controller.dart';

void main() {
  group('SND-001–SND-004 — RecipientEntryController', () {
    late FakeRecipientDirectory directory;
    late RecipientEntryController controller;

    setUp(() {
      directory = const FakeRecipientDirectory();
      controller = RecipientEntryController(directory);
    });

    test('initial state is empty and cannot continue', () {
      expect(controller.state.accountNumber, isEmpty);
      expect(controller.state.status, equals(RecipientResolutionStatus.idle));
      expect(controller.state.resolvedRecipient, isNull);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.canContinue, isFalse);
    });

    test('typing fewer than 10 digits updates text but keeps status idle', () {
      controller.onAccountNumberChanged('01234');

      expect(controller.state.accountNumber, equals('01234'));
      expect(controller.state.status, equals(RecipientResolutionStatus.idle));
      expect(controller.state.resolvedRecipient, isNull);
      expect(controller.state.canContinue, isFalse);
    });

    test('typing 10 valid digits automatically resolves recipient', () async {
      controller.onAccountNumberChanged('0123456789');

      // Wait for async resolution to complete
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.state.status,
        equals(RecipientResolutionStatus.resolved),
      );
      expect(controller.state.resolvedRecipient?.name, equals('John Doe'));
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.canContinue, isTrue);
    });

    test(
      'typing 10 unknown digits sets invalid status with error message',
      () async {
        controller.onAccountNumberChanged('9999999999');

        await Future<void>.delayed(Duration.zero);

        expect(
          controller.state.status,
          equals(RecipientResolutionStatus.invalid),
        );
        expect(controller.state.resolvedRecipient, isNull);
        expect(
          controller.state.errorMessage,
          equals('Recipient not found. Enter a valid account number.'),
        );
        expect(controller.state.canContinue, isFalse);
      },
    );

    test(
      'resolving empty string returns required error (SND-002 / UI-SND-02)',
      () async {
        await controller.resolveRecipient('');

        expect(
          controller.state.status,
          equals(RecipientResolutionStatus.invalid),
        );
        expect(
          controller.state.errorMessage,
          equals('Enter who you are sending to.'),
        );
        expect(controller.state.canContinue, isFalse);
      },
    );

    test('resolving non-10-digit number returns length error (SND-003 / UI-SND-03)', () async {
      await controller.resolveRecipient('123');

      expect(
        controller.state.status,
        equals(RecipientResolutionStatus.invalid),
      );
      expect(
        controller.state.errorMessage,
        equals('Enter a valid 10-digit account number.'),
      );
      expect(controller.state.canContinue, isFalse);
    });

    test('validateAndSubmit on empty triggers required error', () {
      Recipient? passedRecipient;
      controller.validateAndSubmit(onContinue: (r) => passedRecipient = r);

      expect(
        controller.state.errorMessage,
        equals('Enter who you are sending to.'),
      );
      expect(passedRecipient, isNull);
    });

    test(
      'validateAndSubmit with resolved recipient invokes onContinue callback',
      () async {
        await controller.resolveRecipient('0123456789');
        expect(controller.state.canContinue, isTrue);

        Recipient? passedRecipient;
        controller.validateAndSubmit(onContinue: (r) => passedRecipient = r);

        expect(passedRecipient, isNotNull);
        expect(passedRecipient!.name, equals('John Doe'));
      },
    );

    test('clear resets state to pristine empty condition', () async {
      await controller.resolveRecipient('0123456789');
      expect(controller.state.canContinue, isTrue);

      controller.clear();

      expect(controller.state.accountNumber, isEmpty);
      expect(controller.state.status, equals(RecipientResolutionStatus.idle));
      expect(controller.state.resolvedRecipient, isNull);
      expect(controller.state.canContinue, isFalse);
    });
  });
}
