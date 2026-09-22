import 'package:flutter/material.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';

/// Top-level coordinator for the Send Money flow.
///
/// Implements ASM-005 (Recipient -> Amount -> Confirm).
class SendMoneyFlowScreen extends StatefulWidget {
  const SendMoneyFlowScreen({super.key});

  @override
  State<SendMoneyFlowScreen> createState() => _SendMoneyFlowScreenState();
}

class _SendMoneyFlowScreenState extends State<SendMoneyFlowScreen> {
  Recipient? _selectedRecipient;
  Money? _enteredAmount;

  void _onRecipientSelected(Recipient recipient) {
    setState(() {
      _selectedRecipient = recipient;
    });
  }

  void _onBackToRecipient() {
    setState(() {
      _selectedRecipient = null;
      _enteredAmount = null;
    });
  }

  void _onAmountConfirmed(Money amount) {
    setState(() {
      _enteredAmount = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRecipient == null) {
      return RecipientEntryScreen(onContinue: _onRecipientSelected);
    }

    if (_enteredAmount != null) {
      // T-SND-003 will replace this with full ConfirmationScreen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Confirm Transfer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _enteredAmount = null),
          ),
        ),
        body: Center(
          child: Text(
            'Confirm ${_enteredAmount!.format()} to ${_selectedRecipient!.name}',
          ),
        ),
      );
    }

    return AmountEntryScreen(
      recipient: _selectedRecipient!,
      onBack: _onBackToRecipient,
      onContinue: _onAmountConfirmed,
    );
  }
}
