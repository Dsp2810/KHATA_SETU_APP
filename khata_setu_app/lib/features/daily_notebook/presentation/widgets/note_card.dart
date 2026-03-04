import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';


/// A card widget representing a single daily note in the list.
/// Supports selection mode, priority badges, overdue indicators,
/// and swipe-to-complete/delete.
class NoteCard extends StatelessWidget {
  final DailyNoteModel note;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSelect;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.isSelected = false,
    this.isSelectMode = false,
    this.onLongPress,
    this.onComplete,
    this.onDelete,
    this.onToggleSelect,
  });

  Color _priorityColor() {
    switch (note.priority) {
      case 'high':
        return AppColors.credit;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon() {
    switch (note.status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  Color _statusColor() {
    switch (note.status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.grey400;
      default:
        return note.isOverdue ? AppColors.credit : AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onLongPress: onLongPress,
      child: SurfaceCard(
      onTap: isSelectMode ? onToggleSelect : onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select checkbox or status icon
          if (isSelectMode)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
              child: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : AppColors.grey400,
                size: 22,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
              child: Icon(
                _statusIcon(),
                color: _statusColor(),
                size: 20,
              ),
            ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + priority badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: note.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: note.isCompleted
                              ? context.textTertiaryColor
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildPriorityBadge(),
                  ],
                ),

                // Customer name + date
                if (note.customerName != null ||
                    note.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note.customerName ??
                        (note.description ?? ''),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: AppSpacing.xs),

                // Bottom row: date, items count, tags, amount
                Row(
                  children: [
                    // Date
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: context.textTertiaryColor),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(note.dateKey),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: note.isOverdue
                            ? AppColors.credit
                            : context.textTertiaryColor,
                        fontWeight:
                            note.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),

                    // Items count
                    if (note.hasItems) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.list_alt_rounded,
                          size: 12, color: context.textTertiaryColor),
                      const SizedBox(width: 3),
                      Text(
                        '${note.itemCount}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                    ],

                    // Tags
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.label_outline_rounded,
                          size: 12, color: context.textTertiaryColor),
                      const SizedBox(width: 3),
                      Text(
                        note.tags.first,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                      if (note.tags.length > 1)
                        Text(
                          ' +${note.tags.length - 1}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.textTertiaryColor,
                          ),
                        ),
                    ],

                    const Spacer(),

                    // Amount
                    if (note.totalAmount > 0)
                      Text(
                        '${AppConstants.currencySymbol}${note.totalAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.credit,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),

                // Overdue or reminder indicator
                if (note.isOverdue || note.isReminderOverdue) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.credit.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      note.isReminderOverdue
                          ? 'Reminder overdue'
                          : 'Overdue',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.credit,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );

    // Wrap with Dismissible for swipe actions (only when not in select mode)
    if (!isSelectMode && note.isPending) {
      card = Dismissible(
        key: Key('note_${note.id}'),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Text('Complete',
                  style: TextStyle(color: AppColors.success)),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.credit.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Delete',
                  style: TextStyle(color: AppColors.credit)),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.delete_outline, color: AppColors.credit),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onComplete?.call();
          } else {
            onDelete?.call();
          }
          return false; // Don't actually dismiss — let BLoC handle it
        },
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: card,
    );
  }

  Widget _buildPriorityBadge() {
    if (note.priority == 'medium') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _priorityColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        note.priority.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _priorityColor(),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatDate(String dateKey) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final noteDay = DateTime(date.year, date.month, date.day);

      if (noteDay == today) return 'Today';
      if (noteDay == yesterday) return 'Yesterday';
      return DateFormat('dd MMM').format(date);
    } catch (_) {
      return dateKey;
    }
  }
}
