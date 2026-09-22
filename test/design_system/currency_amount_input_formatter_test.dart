import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/design_system/components/fields/currency_amount_input_formatter.dart';

void main() {
  group('CurrencyAmountInputFormatter', () {
    const formatter = CurrencyAmountInputFormatter();

    TextEditingValue format(String text, {int? offset, TextEditingValue? old}) {
      final oldValue = old ?? TextEditingValue.empty;
      final newValue = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset ?? text.length),
      );
      return formatter.formatEditUpdate(oldValue, newValue);
    }

    test('empty string returns empty value', () {
      final result = format('');
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });

    test('formats single digit and numbers under 1000 without commas', () {
      expect(format('1').text, '1');
      expect(format('15').text, '15');
      expect(format('150').text, '150');
    });

    test('formats 4-digit number with thousands comma', () {
      final result = format('1500');
      expect(result.text, '1,500');
      expect(result.selection.baseOffset, 5);
    });

    test('formats large numbers with multiple thousands commas', () {
      expect(format('10000').text, '10,000');
      expect(format('100000').text, '100,000');
      expect(format('1000000').text, '1,000,000');
      expect(format('123456789').text, '123,456,789');
    });

    test('formats decimal values up to 2 decimal places', () {
      expect(format('1500.').text, '1,500.');
      expect(format('1500.5').text, '1,500.5');
      expect(format('1500.50').text, '1,500.50');
      // Truncates 3rd decimal digit
      expect(format('1500.509').text, '1,500.50');
    });

    test('ignores non-numeric characters', () {
      expect(format('abc1500xyz').text, '1,500');
      expect(format('₦1500').text, '1,500');
    });

    test('preserves cursor position when typing at the end', () {
      final old = format('150');
      final result = format('1500', old: old);
      expect(result.text, '1,500');
      expect(result.selection.baseOffset, 5);
    });

    test('preserves cursor position when inserting digit in the middle', () {
      // User has 1,500 with cursor after 1 (offset 2). User types 2 to make 12500 -> 12,500
      const old = TextEditingValue(
        text: '1,500',
        selection: TextSelection.collapsed(offset: 2),
      );
      const neu = TextEditingValue(
        text: '1,2500',
        selection: TextSelection.collapsed(offset: 3),
      );
      final result = formatter.formatEditUpdate(old, neu);
      expect(result.text, '12,500');
      expect(result.selection.baseOffset, 3);
    });

    test('handles backspacing over a comma cleanly', () {
      // User has 1,500 with cursor after comma (offset 2). Backspaces.
      const old = TextEditingValue(
        text: '1,500',
        selection: TextSelection.collapsed(offset: 2),
      );
      // Keyboard deletes the comma:
      const neu = TextEditingValue(
        text: '1500',
        selection: TextSelection.collapsed(offset: 1),
      );
      final result = formatter.formatEditUpdate(old, neu);
      // Deletes the digit before the comma ('1'), resulting in 500:
      expect(result.text, '500');
      expect(result.selection.baseOffset, 0);
    });

    test('handles leading zero stripping on multi-digit numbers', () {
      expect(format('05').text, '5');
      expect(format('01500').text, '1,500');
      expect(format('0').text, '0');
      expect(format('0.50').text, '0.50');
    });
  });
}
