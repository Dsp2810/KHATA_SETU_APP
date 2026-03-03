import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet for applying filters to daily notes.
class NoteFilterSheet extends StatefulWidget {
  final NoteFilters currentFilters;
  final ValueChanged<NoteFilters> onApply;

  const NoteFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<NoteFilterSheet> createState() => _NoteFilterSheetState();
}

class _NoteFilterSheetState extends State<NoteFilterSheet> {
  late NoteFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  void _apply() {
    widget.onApply(_filters);
    Navigator.pop(context);
  }

  void _clear() {
    setState(() => _filters = NoteFilters.empty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Filter Notes', style: AppTextStyles.h4),
              const Spacer(),
              if (_filters.hasActiveFilters)
                TextButton(
                  onPressed: _clear,
                  child: Text('Clear All',
                      style: TextStyle(color: AppColors.credit)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Status filter
          Text('Status',
              style: AppTextStyles.labelMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: ['pending', 'completed', 'cancelled'].map((s) {
              final selected = _filters.status == s;
              return FilterChip(
                label: Text(s[0].toUpperCase() + s.substring(1)),
                selected: selected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                onSelected: (_) {
                  setState(() {
                    _filters = selected
                        ? _filters.copyWith(clearStatus: true)
                        : _filters.copyWith(status: s);
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // Priority filter
          Text('Priority',
              style: AppTextStyles.labelMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ('low', AppColors.info, Icons.arrow_downward_rounded),
              ('medium', AppColors.warning, Icons.remove_rounded),
              ('high', AppColors.credit, Icons.arrow_upward_rounded),
            ].map((entry) {
              final (value, color, icon) = entry;
              final selected = _filters.priority == value;
              return FilterChip(
                avatar: Icon(icon, size: 16, color: selected ? color : null),
                label:
                    Text(value[0].toUpperCase() + value.substring(1)),
                selected: selected,
                selectedColor: color.withValues(alpha: 0.15),
                checkmarkColor: color,
                onSelected: (_) {
                  setState(() {
                    _filters = selected
                        ? _filters.copyWith(clearPriority: true)
                        : _filters.copyWith(priority: value);
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          // Date range
          Text('Date Range',
              style: AppTextStyles.labelMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _DatePickerButton(
                  label: 'From',
                  date: _filters.startDate,
                  onPicked: (d) => setState(() {
                    _filters = _filters.copyWith(startDate: d);
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DatePickerButton(
                  label: 'To',
                  date: _filters.endDate,
                  onPicked: (d) => setState(() {
                    _filters = _filters.copyWith(endDate: d);
                  }),
                ),
              ),
              if (_filters.startDate != null || _filters.endDate != null)
                IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: 18, color: AppColors.credit),
                  onPressed: () => setState(() {
                    _filters = _filters.copyWith(clearDateRange: true);
                  }),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Sort by
          Text('Sort By',
              style: AppTextStyles.labelMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ('noteDate', 'Date'),
              ('priority', 'Priority'),
              ('totalAmount', 'Amount'),
              ('createdAt', 'Created'),
            ].map((entry) {
              final (value, label) = entry;
              final selected = _filters.sortBy == value;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      // Toggle sort order
                      _filters = _filters.copyWith(
                        sortOrder:
                            _filters.sortOrder == 'asc' ? 'desc' : 'asc',
                      );
                    } else {
                      _filters = _filters.copyWith(
                          sortBy: value, sortOrder: 'desc');
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_filters.sortBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    _filters.sortOrder == 'asc'
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _filters.sortOrder == 'asc'
                        ? 'Ascending'
                        : 'Descending',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                _filters.hasActiveFilters
                    ? 'Apply ${_filters.activeFilterCount} Filters'
                    : 'Apply',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 14, color: context.textTertiaryColor),
          const SizedBox(width: 6),
          Text(
            date != null
                ? DateFormat('dd MMM yy').format(date!)
                : label,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  date != null ? null : context.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
