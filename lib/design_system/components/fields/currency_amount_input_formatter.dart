import 'package:flutter/services.dart';

/// A [TextInputFormatter] that formats numeric amounts with thousands separators (commas)
/// and constrains decimal fractions to at most 2 decimal places.
///
/// Examples:
/// - `1500` -> `1,500`
/// - `10000` -> `10,000`
/// - `1500.5` -> `1,500.5`
/// - `1500.50` -> `1,500.50`
/// - `1000000.00` -> `1,000,000.00`
///
/// Maintains exact cursor positions during typing, pasting, and backspacing.
class CurrencyAmountInputFormatter extends TextInputFormatter {
  const CurrencyAmountInputFormatter({
    this.maxDecimalDigits = 2,
    this.allowDecimals = true,
  });

  final int maxDecimalDigits;
  final bool allowDecimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    if (rawText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Handle backspacing over a comma:
    // If the user hit backspace directly on a comma, delete the preceding digit as well.
    String textToFormat = rawText;
    int cursorInNew = newValue.selection.baseOffset;

    if (oldValue.selection.isCollapsed &&
        oldValue.selection.baseOffset > 0 &&
        oldValue.text.length - 1 == rawText.length &&
        oldValue.selection.baseOffset == cursorInNew + 1 &&
        oldValue.selection.baseOffset <= oldValue.text.length &&
        oldValue.text[oldValue.selection.baseOffset - 1] == ',') {
      final digitIndex = cursorInNew - 1;
      if (digitIndex >= 0 && digitIndex < textToFormat.length) {
        textToFormat =
            textToFormat.substring(0, digitIndex) +
            textToFormat.substring(digitIndex + 1);
        cursorInNew = digitIndex;
      }
    }

    // Strip out all characters except digits and decimal point
    final buffer = StringBuffer();
    bool hasDot = false;
    int nonCommaCharsBeforeCursor = 0;

    for (int i = 0; i < textToFormat.length; i++) {
      final char = textToFormat[i];
      final code = textToFormat.codeUnitAt(i);
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(char);
        if (i < cursorInNew) {
          nonCommaCharsBeforeCursor++;
        }
      } else if (char == '.' && allowDecimals && !hasDot) {
        hasDot = true;
        buffer.write(char);
        if (i < cursorInNew) {
          nonCommaCharsBeforeCursor++;
        }
      }
    }

    final cleanedText = buffer.toString();
    if (cleanedText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Split into integer part and decimal part
    final dotIndex = cleanedText.indexOf('.');
    String integerPart = dotIndex != -1
        ? cleanedText.substring(0, dotIndex)
        : cleanedText;
    String? decimalPart = dotIndex != -1
        ? cleanedText.substring(dotIndex + 1)
        : null;

    // Constrain decimal digits
    if (decimalPart != null && decimalPart.length > maxDecimalDigits) {
      decimalPart = decimalPart.substring(0, maxDecimalDigits);
    }

    // Remove leading zeros from integer part unless it's just '0'
    if (integerPart.length > 1 && integerPart.startsWith('0')) {
      int firstNonZero = 0;
      while (firstNonZero < integerPart.length - 1 &&
          integerPart[firstNonZero] == '0') {
        firstNonZero++;
      }
      final strippedZeros = firstNonZero;
      integerPart = integerPart.substring(firstNonZero);
      nonCommaCharsBeforeCursor = (nonCommaCharsBeforeCursor - strippedZeros)
          .clamp(0, cleanedText.length);
    }

    // Format integer part with thousands commas
    final formattedInteger = _addCommas(integerPart);

    // Build the final formatted text
    final formattedBuffer = StringBuffer(formattedInteger);
    if (hasDot) {
      formattedBuffer.write('.');
      if (decimalPart != null && decimalPart.isNotEmpty) {
        formattedBuffer.write(decimalPart);
      }
    }
    final formattedText = formattedBuffer.toString();

    // Map cursor position
    int newCursorOffset = 0;
    int charsCounted = 0;

    for (int i = 0; i < formattedText.length; i++) {
      if (charsCounted >= nonCommaCharsBeforeCursor) {
        break;
      }
      if (formattedText[i] != ',') {
        charsCounted++;
      }
      newCursorOffset = i + 1;
    }

    // If cursor lands directly before a comma, advance past the comma
    // so the user types ahead of formatting separators.
    if (newCursorOffset < formattedText.length &&
        formattedText[newCursorOffset] == ',') {
      newCursorOffset++;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, formattedText.length),
      ),
    );
  }

  /// Formats an integer string with comma thousands separators.
  static String _addCommas(String intString) {
    if (intString.isEmpty) return '';
    final chars = intString.split('');
    final buffer = StringBuffer();
    final len = chars.length;

    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return buffer.toString();
  }
}
