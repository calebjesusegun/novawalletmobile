import 'package:flutter/material.dart';
import 'package:novawallet/core/time/date_time_formatter.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Modal bottom sheet date picker matching UI-NSV-06.
///
/// Implements requirement NSV-007 (target-date picker) and enforces NSV-006
/// (requiring target date in the future).
class TargetDatePickerSheet extends StatefulWidget {
  const TargetDatePickerSheet({
    super.key,
    this.initialDate,
    this.firstSelectableDate,
  });

  /// Currently selected or initial date to display.
  final DateTime? initialDate;

  /// The earliest date selectable. Defaults to tomorrow at start-of-day.
  final DateTime? firstSelectableDate;

  /// Convenience method to show this picker as a modal bottom sheet.
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstSelectableDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TargetDatePickerSheet(
        initialDate: initialDate,
        firstSelectableDate: firstSelectableDate,
      ),
    );
  }

  @override
  State<TargetDatePickerSheet> createState() => _TargetDatePickerSheetState();
}

class _TargetDatePickerSheetState extends State<TargetDatePickerSheet> {
  late DateTime _displayedMonth;
  DateTime? _selectedDate;
  late final DateTime _earliestDate;

  static const List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _earliestDate =
        widget.firstSelectableDate ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    if (widget.initialDate != null &&
        widget.initialDate!.isAfter(
          _earliestDate.subtract(const Duration(days: 1)),
        )) {
      _selectedDate = widget.initialDate;
      _displayedMonth = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
      );
    } else {
      _selectedDate = null;
      _displayedMonth = DateTime(_earliestDate.year, _earliestDate.month);
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  bool _isDateSelectable(DateTime date) {
    final dayOnly = DateTime(date.year, date.month, date.day);
    final earliestDay = DateTime(
      _earliestDate.year,
      _earliestDate.month,
      _earliestDate.day,
    );
    return !dayOnly.isBefore(earliestDay);
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final totalDays = _daysInMonth(year, month);
    // weekday is 1 for Monday, 7 for Sunday
    final firstWeekday = DateTime(year, month, 1).weekday;
    final leadingBlanks = firstWeekday - 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: AppRadii.xlRadius),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space12,
        AppSpacing.space24,
        AppSpacing.space24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: AppRadii.pillBorderRadius,
                  ),
                ),
              ),
              AppSpacing.gapVertical16,

              // Header title
              Text(
                'Select target date',
                textAlign: TextAlign.center,
                style: AppTypography.titleBold18.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapVertical16,

              // Month navigation bar: < Month Year >
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.textPrimary,
                    tooltip: 'Previous month',
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateTimeFormatter.formatMonthYear(_displayedMonth),
                    style: AppTypography.titleBold16.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.textPrimary,
                    tooltip: 'Next month',
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              AppSpacing.gapVertical12,

              // Weekdays header
              Row(
                children: [
                  for (final w in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: AppTypography.labelRegular12.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.gapVertical8,

              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadingBlanks + totalDays,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  mainAxisExtent: 38,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) {
                    return const SizedBox.shrink();
                  }
                  final day = index - leadingBlanks + 1;
                  final date = DateTime(year, month, day);
                  final selectable = _isDateSelectable(date);
                  final isSelected = _isSameDay(_selectedDate, date);

                  return Semantics(
                    label:
                        '${DateTimeFormatter.formatDate(date)}${isSelected ? ", selected" : ""}${!selectable ? ", disabled" : ""}',
                    selected: isSelected,
                    enabled: selectable,
                    button: selectable,
                    child: InkWell(
                      onTap: selectable
                          ? () {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAction
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: AppTypography.bodyMedium14.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : (selectable
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AppSpacing.gapVertical24,

              // Confirm date action button
              AppButton(
                label: 'Confirm date',
                onPressed: _selectedDate != null
                    ? () => Navigator.of(context).pop(_selectedDate)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
