import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/fields/app_amount_field.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/controllers/amount_entry_controller.dart';

/// Screen for entering amount and validating against spendable balance.
///
/// Implements SND-005, SND-006, SND-007, SND-008, MNY-003, MNY-006.
/// Visual references: UI-SND-05 through UI-SND-09.
class AmountEntryScreen extends ConsumerStatefulWidget {
  const AmountEntryScreen({
    super.key,
    required this.recipient,
    this.onBack,
    this.onContinue,
  });

  final Recipient recipient;
  final VoidCallback? onBack;
  final void Function(Money amount)? onContinue;

  @override
  ConsumerState<AmountEntryScreen> createState() => _AmountEntryScreenState();
}

class _AmountEntryScreenState extends ConsumerState<AmountEntryScreen> {
  late final TextEditingController _amountController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        ref
            .read(amountEntryControllerProvider(widget.recipient).notifier)
            .validate();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'recently';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(amountEntryControllerProvider(widget.recipient));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Money', style: AppTypography.titleBold18),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.insetsAll24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipient Header Summary Chip
                    AppCard(
                      padding: AppSpacing.insetsAll12,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.blue50,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.recipient.name.isNotEmpty
                                  ? widget.recipient.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'R',
                              style: AppTypography.labelBold14.copyWith(
                                color: AppColors.primaryAction,
                              ),
                            ),
                          ),
                          AppSpacing.gapHorizontal12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Sending to ${widget.recipient.name}',
                                  style: AppTypography.labelBold14,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                AppSpacing.gapVertical4,
                                Text(
                                  '${widget.recipient.bankName} • ${widget.recipient.accountNumber}',
                                  style: AppTypography.bodyRegular14.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (widget.onBack != null)
                            TextButton(
                              onPressed: widget.onBack,
                              child: const Text('Change'),
                            ),
                        ],
                      ),
                    ),

                    AppSpacing.gapVertical16,

                    // Offline System Notification (UI-SND-09 / SND-008)
                    if (state.isOffline) ...[
                      AppSystemNotification.offline(
                        message:
                            "You're offline. Showing balance from ${_formatTimestamp(state.lastUpdatedAt)}. Transfers will be queued securely.",
                      ),
                      AppSpacing.gapVertical16,
                    ],

                    // Available balance helper indicator
                    const Text(
                      'How much would you like to send?',
                      style: AppTypography.titleBold18,
                    ),
                    AppSpacing.gapVertical4,
                    Text(
                      'Available: ${state.spendableBalance.format()}${state.isOffline ? " (Offline)" : ""}',
                      style: AppTypography.bodyRegular14.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    AppSpacing.gapVertical24,

                    // Amount Entry Field (UI-SND-05, UI-SND-06, UI-SND-07, UI-SND-08)
                    AppAmountField(
                      controller: _amountController,
                      focusNode: _focusNode,
                      autofocus: true,
                      errorText: state.validationError,
                      onChanged: (value) {
                        ref
                            .read(
                              amountEntryControllerProvider(widget.recipient)
                                  .notifier,
                            )
                            .onAmountChanged(value);
                      },
                    ),

                    // Balance after transfer preview (UI-SND-06)
                    if (state.balanceAfter != null) ...[
                      AppSpacing.gapVertical16,
                      Container(
                        padding: AppSpacing.insetsAll16,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Balance after transfer',
                                style: AppTypography.bodyRegular14.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            AppSpacing.gapHorizontal8,
                            Text(
                              state.balanceAfter!.format(),
                              style: AppTypography.labelBold14.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Continue Action Button (enabled only when amount is valid)
            Padding(
              padding: AppSpacing.insetsAll24,
              child: AppButton(
                label: 'Continue',
                onPressed: state.canContinue
                    ? () => widget.onContinue?.call(state.amount)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
