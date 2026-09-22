import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/fields/app_amount_field.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/controllers/contribute_amount_controller.dart';

/// Screen for entering contribution amount and previewing projected progress.
///
/// Implements requirements:
/// - NSV-009: Show contribution amount entry and projected progress.
/// - NSV-010: Reject contribution exceeding spendable wallet balance.
/// - MNY-003: Calculate savings goal progress and remaining amount from integer kobo.
/// - MNY-006: Available balance reserves pending debit amounts.
/// - HC-MONEY: Exact integer kobo calculations without floating-point arithmetic.
/// - HC-ACCESSIBILITY: Screen reader semantics and responsive 2.0x text scaling.
/// Visual references: UI-NSV-09, UI-NSV-10.
class ContributeAmountScreen extends ConsumerStatefulWidget {
  const ContributeAmountScreen({
    super.key,
    required this.goal,
    this.onBack,
    this.onContinue,
  });

  final SavingsGoal goal;
  final VoidCallback? onBack;
  final void Function(Money amount)? onContinue;

  @override
  ConsumerState<ContributeAmountScreen> createState() =>
      _ContributeAmountScreenState();
}

class _ContributeAmountScreenState
    extends ConsumerState<ContributeAmountScreen> {
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
            .read(contributeAmountControllerProvider(widget.goal).notifier)
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contributeAmountControllerProvider(widget.goal));
    final controller = ref.read(
      contributeAmountControllerProvider(widget.goal).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contribute', style: AppTypography.titleBold18),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contributing To Header Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contributing to',
                            style: AppTypography.bodyMedium12.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapVertical4,
                          Text(
                            widget.goal.name,
                            style: AppTypography.titleBold16.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapVertical4,
                          Text(
                            'Saved ${widget.goal.savedAmount.formatCompact()} of ${widget.goal.targetAmount.formatCompact()}',
                            style: AppTypography.bodyMedium12.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.gapVertical24,

                    // Amount to add Label
                    Text(
                      'Amount to add',
                      style: AppTypography.titleBold14.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    AppSpacing.gapVertical8,

                    // Amount Entry Field
                    AppAmountField(
                      key: const Key('contribute_amount_field'),
                      controller: _amountController,
                      focusNode: _focusNode,
                      hintText: '0.00',
                      currencySymbol: '₦',
                      errorText: state.validationError,
                      helperText: state.hasError
                          ? null
                          : 'Wallet balance ${state.spendableBalance.format()}',
                      onChanged: controller.onAmountChanged,
                    ),

                    // Projected Progress Preview Card (UI-NSV-09)
                    if (state.amount.isPositive && !state.hasError) ...[
                      AppSpacing.gapVertical20,
                      Semantics(
                        container: true,
                        label:
                            'Projected progress: ${state.projectedSavedAmount.format()} of ${widget.goal.targetAmount.format()}, ${state.projectedPercentage}% complete.',
                        child: AppCard(
                          key: const Key('projected_progress_card'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${state.projectedSavedAmount.formatCompact()} of ${widget.goal.targetAmount.formatCompact()}',
                                      style: AppTypography.bodyMedium14
                                          .copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${state.projectedPercentage}%',
                                    style: AppTypography.titleBold16.copyWith(
                                      color: AppColors.primaryAction,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapVertical12,
                              AppProgressBar(
                                progress: state.projectedProgress
                                    .toProgressFraction(),
                                height: 8.0,
                                fillColor: AppColors.primaryAction,
                                backgroundColor: AppColors.grey100,
                                semanticLabel:
                                    '${state.projectedPercentage}% progress',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Sticky Bottom Continue Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: AppButton(
                key: const Key('contribute_continue_button'),
                label: 'Continue',
                onPressed: state.canContinue
                    ? () {
                        widget.onContinue?.call(state.amount);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
