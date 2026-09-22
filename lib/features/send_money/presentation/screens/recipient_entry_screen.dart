import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_text_field.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/controllers/recipient_entry_controller.dart';
import 'package:novawallet/features/send_money/presentation/widgets/resolved_recipient_card.dart';

/// Screen for entering and resolving a recipient account number.
///
/// Implements ASM-005, SND-001, SND-002, SND-003, SND-004.
/// Visual references: UI-SND-01 through UI-SND-04.
class RecipientEntryScreen extends ConsumerStatefulWidget {
  const RecipientEntryScreen({super.key, this.onContinue});

  /// Callback when user selects a valid resolved recipient and taps Continue.
  final void Function(Recipient recipient)? onContinue;

  @override
  ConsumerState<RecipientEntryScreen> createState() =>
      _RecipientEntryScreenState();
}

class _RecipientEntryScreenState extends ConsumerState<RecipientEntryScreen> {
  late final TextEditingController _accountController;
  late final FocusNode _focusNode;
  bool _hasBeenEdited = false;

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _hasBeenEdited) {
        final text = _accountController.text.trim();
        if (text.isEmpty) {
          ref
              .read(recipientEntryControllerProvider.notifier)
              .resolveRecipient('');
        } else if (text.length < 10) {
          ref
              .read(recipientEntryControllerProvider.notifier)
              .resolveRecipient(text);
        }
      }
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClear() {
    _accountController.clear();
    _hasBeenEdited = false;
    ref.read(recipientEntryControllerProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipientEntryControllerProvider);
    final currentDestination = ref.watch(appNavigationProvider);
    final isCurrentTab = currentDestination == AppDestination.send;

    ref.listen<AppDestination>(appNavigationProvider, (prev, next) {
      if (next == AppDestination.send && state.resolvedRecipient == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Money', style: AppTypography.titleBold18),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
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
                    // Headline and descriptive subtitle
                    const Text(
                      'Who are you sending to?',
                      style: AppTypography.titleBold22,
                    ),
                    AppSpacing.gapVertical8,
                    Text(
                      'Transfer funds securely even while offline.',
                      style: AppTypography.bodyRegular14.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapVertical24,

                    // Recipient Account Input Field
                    AppTextField(
                      controller: _accountController,
                      focusNode: _focusNode,
                      autofocus: isCurrentTab,
                      label: 'Recipient account number',
                      hintText: 'Enter 10-digit account number',
                      errorText: state.errorMessage,
                      helperText:
                          state.resolvedRecipient == null && !state.hasError
                          ? 'Enter a 10-digit NUBAN account number'
                          : null,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (value) {
                        _hasBeenEdited = true;
                        ref
                            .read(recipientEntryControllerProvider.notifier)
                            .onAccountNumberChanged(value);
                      },
                      onSubmitted: (value) {
                        ref
                            .read(recipientEntryControllerProvider.notifier)
                            .resolveRecipient(value);
                      },
                    ),

                    // Resolution loading indicator
                    if (state.status ==
                        RecipientResolutionStatus.resolving) ...[
                      AppSpacing.gapVertical16,
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryAction,
                            ),
                          ),
                          AppSpacing.gapHorizontal12,
                          Text(
                            'Verifying recipient account...',
                            style: AppTypography.bodyRegular14.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Resolved Recipient presentation (UI-SND-04)
                    if (state.resolvedRecipient != null) ...[
                      AppSpacing.gapVertical16,
                      ResolvedRecipientCard(
                        recipient: state.resolvedRecipient!,
                        onClear: _onClear,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Continue Action Button (enabled only when resolved)
            Padding(
              padding: AppSpacing.insetsAll24,
              child: AppButton(
                label: 'Continue',
                onPressed: state.canContinue
                    ? () => widget.onContinue?.call(state.resolvedRecipient!)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
