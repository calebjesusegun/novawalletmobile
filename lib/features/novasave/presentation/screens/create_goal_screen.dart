import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/ids/uuid.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/time/date_time_formatter.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_text_field.dart';
import 'package:novawallet/design_system/components/fields/currency_amount_input_formatter.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/goal_details_screen.dart';
import 'package:novawallet/features/novasave/presentation/widgets/target_date_picker_sheet.dart';

/// Screen for creating a new savings goal (UI-NSV-04, UI-NSV-05, UI-NSV-07).
///
/// Implements requirements:
/// - NSV-003: Create goal with name, target amount, target date.
/// - NSV-004: Require goal name (UI-NSV-05).
/// - NSV-005: Require positive integer-kobo target amount (UI-NSV-05, HC-MONEY).
/// - NSV-006: Require future target date (UI-NSV-05).
/// - NSV-007: Provide target-date picker (UI-NSV-06).
/// - HC-ACCESSIBILITY: Accessible semantics and responsive layout.
class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key, this.onGoalCreated});

  /// Optional callback invoked when a goal is created, useful for testing or custom navigation.
  final ValueChanged<SavingsGoal>? onGoalCreated;

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();

  DateTime? _selectedDate;

  String? _nameError;
  String? _amountError;
  String? _dateError;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _amountController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _amountController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  /// Parses a string into integer kobo [Money], or returns null if invalid.
  Money? _parseAmount(String input) {
    final sanitized = input.trim().replaceAll('₦', '').replaceAll(',', '');
    if (sanitized.isEmpty) return null;

    // Check for decimal format e.g. 500 or 500.00
    final parts = sanitized.split('.');
    if (parts.length > 2) return null;

    final nairaPart = parts[0].isEmpty ? 0 : int.tryParse(parts[0]);
    if (nairaPart == null) return null;

    var koboPart = 0;
    if (parts.length == 2) {
      final decStr = parts[1].padRight(2, '0');
      if (decStr.length > 2) return null;
      final parsedDec = int.tryParse(decStr);
      if (parsedDec == null) return null;
      koboPart = parsedDec;
    }

    final totalKobo = (nairaPart * 100) + koboPart;
    if (totalKobo <= 0) return null;

    return Money.fromKobo(totalKobo);
  }

  bool _validateForm() {
    var isValid = true;

    // 1. Goal name validation (NSV-004)
    if (_nameController.text.trim().isEmpty) {
      _nameError = 'Enter a name for your goal.';
      isValid = false;
    } else {
      _nameError = null;
    }

    // 2. Target amount validation (NSV-005, HC-MONEY)
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount.isZero || amount.isNegative) {
      _amountError = 'Enter a target amount greater than ₦0.00.';
      isValid = false;
    } else {
      _amountError = null;
    }

    // 3. Target date validation (NSV-006)
    if (_selectedDate == null ||
        !DateTimeFormatter.isFutureDate(_selectedDate!)) {
      _dateError = 'Choose a date in the future.';
      isValid = false;
    } else {
      _dateError = null;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _selectTargetDate() async {
    final picked = await TargetDatePickerSheet.show(
      context,
      initialDate: _selectedDate,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateTimeFormatter.formatDate(picked);
        _dateError = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();
    final amount = _parseAmount(_amountController.text)!;
    final date = _selectedDate!;

    final goal = SavingsGoal(
      id: Uuid.v4(),
      name: name,
      targetAmount: amount,
      targetDate: date,
    );

    try {
      final repo = ref.read(novaSaveRepositoryProvider);
      await repo.createGoal(goal);

      if (!mounted) return;

      if (widget.onGoalCreated != null) {
        widget.onGoalCreated!(goal);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                GoalDetailsScreen(goalId: goal.id, initialGoal: goal),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool get _hasAnyInput =>
      _nameController.text.isNotEmpty ||
      _amountController.text.isNotEmpty ||
      _selectedDate != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create goal', style: AppTypography.titleBold18),
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
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
                    // Goal name field (UI-NSV-04, UI-NSV-05)
                    AppTextField(
                      label: 'Goal name',
                      hintText: 'For example, Emergency Fund',
                      autofocus: true,
                      focusNode: _nameFocusNode,
                      controller: _nameController,
                      errorText: _nameError,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        _amountFocusNode.requestFocus();
                      },
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    AppSpacing.gapVertical16,

                    // Target amount field (UI-NSV-04, UI-NSV-05)
                    AppTextField(
                      label: 'Target amount',
                      hintText: '0.00',
                      prefixIcon: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.space16,
                            right: AppSpacing.space8,
                          ),
                          child: Text(
                            '₦',
                            style: AppTypography.bodyMedium16.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      focusNode: _amountFocusNode,
                      controller: _amountController,
                      errorText: _amountError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: const [CurrencyAmountInputFormatter()],
                      onChanged: (_) {
                        if (_amountError != null) {
                          setState(() => _amountError = null);
                        }
                      },
                    ),
                    AppSpacing.gapVertical16,

                    // Target date field (UI-NSV-04, UI-NSV-05, UI-NSV-06)
                    AppTextField(
                      label: 'Target date',
                      hintText: 'Select a date',
                      controller: _dateController,
                      errorText: _dateError,
                      readOnly: true,
                      onTap: _selectTargetDate,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textPrimary,
                        ),
                        tooltip: 'Open date picker',
                        onPressed: _selectTargetDate,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Create Goal Button (UI-NSV-04, UI-NSV-07)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: AppButton(
                label: 'Create Goal',
                isLoading: _isSubmitting,
                onPressed: _hasAnyInput ? _handleSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
