import 'package:flutter/material.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_confirmation_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_result_screen.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

/// Top-level coordinator for the Send Money flow.
///
/// Implements ASM-005 (Recipient -> Amount -> Confirm -> Processing/Result).
class SendMoneyFlowScreen extends StatefulWidget {
  const SendMoneyFlowScreen({super.key});

  @override
  State<SendMoneyFlowScreen> createState() => _SendMoneyFlowScreenState();
}

class _SendMoneyFlowScreenState extends State<SendMoneyFlowScreen> {
  Recipient? _selectedRecipient;
  Money? _enteredAmount;
  FinancialOperation? _submittedOperation;

  void _onRecipientSelected(Recipient recipient) {
    setState(() {
      _selectedRecipient = recipient;
    });
  }

  void _onBackToRecipient() {
    setState(() {
      _selectedRecipient = null;
      _enteredAmount = null;
      _submittedOperation = null;
    });
  }

  void _onAmountConfirmed(Money amount) {
    setState(() {
      _enteredAmount = amount;
    });
  }

  void _onBackToAmount() {
    setState(() {
      _enteredAmount = null;
    });
  }

  void _onTransferSubmitted(FinancialOperation operation) {
    setState(() {
      _submittedOperation = operation;
    });
  }

  void _onFlowDone() {
    setState(() {
      _selectedRecipient = null;
      _enteredAmount = null;
      _submittedOperation = null;
    });
  }

  void _onFlowTryAgain() {
    setState(() {
      _submittedOperation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedOperation != null) {
      return TransferResultScreen(
        operation: _submittedOperation!,
        onDone: _onFlowDone,
        onTryAgain: _onFlowTryAgain,
      );
    }

    if (_selectedRecipient == null) {
      return RecipientEntryScreen(onContinue: _onRecipientSelected);
    }

    if (_enteredAmount != null) {
      return TransferConfirmationScreen(
        recipient: _selectedRecipient!,
        amount: _enteredAmount!,
        onBack: _onBackToAmount,
        onTransferSubmitted: _onTransferSubmitted,
      );
    }

    return AmountEntryScreen(
      recipient: _selectedRecipient!,
      onBack: _onBackToRecipient,
      onContinue: _onAmountConfirmed,
    );
  }
}
