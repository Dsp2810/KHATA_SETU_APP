import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';
import '../bloc/daily_note_bloc.dart';
import '../bloc/daily_note_event.dart';
import '../bloc/daily_note_state.dart';
import '../widgets/note_card.dart';
import '../widgets/note_filter_sheet.dart';
import '../widgets/note_summary_card.dart';

class DailyNotebookPage extends StatefulWidget {
  const DailyNotebookPage({super.key});

  @override
  State<DailyNotebookPage> createState() => _DailyNotebookPageState();
}

class _DailyNotebookPageState extends State<DailyNotebookPage>
    with SingleTickerProviderStateMixin {
  late final DailyNoteBloc _bloc;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<DailyNoteBloc>();
    _bloc.add(const LoadNotes());
    _bloc.add(const LoadSummary());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Infinite scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 200) {
      _bloc.add(const LoadMoreNotes());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchAndFilterBar(context),
                Expanded(child: _buildBody(context)),
              ],
            ),
          ),
        ),
      ),
      // FAB removed - using inline add button in header instead
    );
  }

  // ─── Header ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<DailyNoteBloc, DailyNoteState>(
      bloc: _bloc,
      buildWhen: (p, c) =>
          c is DailyNotesLoaded || c is DailyNoteLoading || c is DailyNoteInitial,
      builder: (context, state) {
        final isSelectMode =
            state is DailyNotesLoaded && state.isSelectMode;
        final selectedCount =
            state is DailyNotesLoaded ? state.selectedCount : 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Row(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    if (isSelectMode) {
                      _bloc.add(const ToggleSelectMode());
                    } else {
                      context.pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    isSelectMode
                        ? Icons.close_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: isSelectMode
                    ? Text(
                        '$selectedCount selected',
                        style: AppTextStyles.h4,
                      )
                    : GradientText(
                        text: context.l10n.dailyBook,
                        style: AppTextStyles.h3,
                      ),
              ),
              if (isSelectMode) ...[
                // Select all
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => _bloc.add(const SelectAllNotes()),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.select_all_rounded,
                        size: 20, color: context.textPrimaryColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Bulk complete
                if (selectedCount > 0)
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => _bloc.add(const BulkCompleteSelected()),
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 20, color: AppColors.success),
                    ),
                  ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  // Bulk delete
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () =>
                          _showBulkDeleteConfirmation(context, selectedCount),
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.credit),
                    ),
                  ),
                ],
              ] else ...[
                // Add entry button - always visible in normal mode
                _buildAddButton(context),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Search + Filter Bar ─────────────────────────────────────

  Widget _buildSearchAndFilterBar(BuildContext context) {
    return BlocBuilder<DailyNoteBloc, DailyNoteState>(
      bloc: _bloc,
      buildWhen: (p, c) => c is DailyNotesLoaded,
      builder: (context, state) {
        final filters = state is DailyNotesLoaded
            ? state.filters
            : NoteFilters.empty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Column(
            children: [
              Row(
                children: [
                  // Search toggle / field
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showSearch
                          ? SurfaceCard(
                              key: const ValueKey('search_field'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Icon(Icons.search_rounded,
                                      size: 20,
                                      color: context.textTertiaryColor),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      textInputAction: TextInputAction.search,
                                      style: AppTextStyles.bodyMedium,
                                      decoration: InputDecoration(
                                        hintText: 'Search notes...',
                                        hintStyle: AppTextStyles.bodySmall
                                            .copyWith(
                                                color: context
                                                    .textTertiaryColor),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10),
                                        isDense: true,
                                      ),
                                      onChanged: (q) =>
                                          _bloc.add(SearchNotes(q)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      _bloc.add(const SearchNotes(''));
                                      setState(() => _showSearch = false);
                                    },
                                    child: Icon(Icons.close_rounded,
                                        size: 18,
                                        color: context.textTertiaryColor),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('search_hidden'),
                            ),
                    ),
                  ),
                  if (!_showSearch) ...[
                    // Search button
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      child: InkWell(
                        onTap: () => setState(() => _showSearch = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(Icons.search_rounded,
                            size: 20, color: context.textPrimaryColor),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  // Filter button
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => _showFilterSheet(context, filters),
                      borderRadius: BorderRadius.circular(12),
                      child: Badge(
                        isLabelVisible: filters.hasActiveFilters,
                        label: Text('${filters.activeFilterCount}'),
                        child: Icon(Icons.tune_rounded,
                            size: 20, color: context.textPrimaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Multi-select button
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => _bloc.add(const ToggleSelectMode()),
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(Icons.checklist_rounded,
                          size: 20, color: context.textPrimaryColor),
                    ),
                  ),
                ],
              ),
              // Active filter chips
              if (filters.hasActiveFilters) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildActiveFilterChips(context, filters),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilterChips(BuildContext context, NoteFilters filters) {
    final chips = <Widget>[];

    if (filters.status != null) {
      chips.add(_filterChip(
        filters.status!,
        () => _bloc.add(UpdateFilters(
            filters.copyWith(clearStatus: true))),
      ));
    }
    if (filters.priority != null) {
      chips.add(_filterChip(
        'Priority: ${filters.priority}',
        () => _bloc.add(UpdateFilters(
            filters.copyWith(clearPriority: true))),
      ));
    }
    if (filters.startDate != null || filters.endDate != null) {
      chips.add(_filterChip(
        'Date range',
        () => _bloc.add(UpdateFilters(
            filters.copyWith(clearDateRange: true))),
      ));
    }

    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips,
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Chip(
        label: Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.primary)),
        deleteIcon: Icon(Icons.close, size: 14, color: AppColors.primary),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, NoteFilters currentFilters) {
    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteFilterSheet(
        currentFilters: currentFilters,
        onApply: (filters) => _bloc.add(UpdateFilters(filters)),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<DailyNoteBloc, DailyNoteState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state is DailyNoteBulkActionDone) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          // Reload list after bulk action
          _bloc.add(const LoadNotes());
          _bloc.add(const LoadSummary());
        }
        if (state is DailyNoteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.credit,
            ),
          );
        }
        // Note: DailyNoteSaved/DailyNoteDeleted handled via _navigateToEditor await
      },
      // Rebuild for list-related states only.
      // DailyNoteInitial is included because SaveNote/DeleteNote now reset to Initial.
      buildWhen: (p, c) =>
          c is DailyNoteLoading ||
          c is DailyNotesLoaded ||
          c is DailyNoteInitial ||
          c is DailyNoteError,
      builder: (context, state) {
        // Loading state - show spinner
        if (state is DailyNoteLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Loaded state - show list or empty
        if (state is DailyNotesLoaded) {
          if (state.notes.isEmpty && !state.filters.hasActiveFilters &&
              state.searchQuery.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildNotesList(context, state);
        }

        // Error state - show error with retry
        if (state is DailyNoteError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.credit),
                const SizedBox(height: AppSpacing.md),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => _bloc.add(const LoadNotes()),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }

        // Initial state or any other - show loading to trigger first load
        // This handles DailyNoteInitial which we emit after save/delete
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.noDailyNotes,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.noDailyNotesSubtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, DailyNotesLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => _bloc.add(const RefreshNotes()),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        itemCount: _calculateItemCount(state),
        itemBuilder: (context, index) {
          // Summary card at position 0
          if (index == 0 && state.summary != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: NoteSummaryCard(summary: state.summary!),
            );
          }

          // Adjust index for summary offset
          final noteIndex =
              state.summary != null ? index - 1 : index;

          // Empty search/filter result message
          if (state.notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.grey400),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No notes matching your criteria',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => _bloc.add(const ClearFilters()),
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Loading more indicator
          if (noteIndex >= state.notes.length) {

            
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(
                        '${state.totalCount} notes total',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: context.textTertiaryColor),
                      ),
              ),
            );
          }

          final note = state.notes[noteIndex];

          return NoteCard(
            note: note,
            isSelected: state.isSelected(note.id),
            isSelectMode: state.isSelectMode,
            onTap: () => _navigateToEditor(context, noteId: note.id),
            onLongPress: () {
              if (!state.isSelectMode) {
                _bloc.add(const ToggleSelectMode());
              }
              _bloc.add(ToggleNoteSelection(note.id));
            },
            onComplete: () => _bloc.add(CompleteNote(note.id)),
            onDelete: () => _showDeleteConfirmation(context, note),
            onToggleSelect: () =>
                _bloc.add(ToggleNoteSelection(note.id)),
          );
        },
      ),
    );
  }

  int _calculateItemCount(DailyNotesLoaded state) {
    int count = state.notes.length;
    if (state.summary != null) count += 1; // summary card
    if (state.notes.isEmpty && (state.filters.hasActiveFilters ||
        state.searchQuery.isNotEmpty)) {
      return (state.summary != null ? 1 : 0) + 1; // empty result msg
    }
    if (state.hasMore || state.notes.isNotEmpty) count += 1; // footer
    return count;
  }

  // ─── Add Button (in header) ───────────────────────────────────

  /// Builds a gradient "+" add button for the header.
  /// This is always visible when not in select mode - no BLoC state dependency.
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToEditor(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              context.l10n.add,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to editor and ALWAYS refresh list when returning.
  /// This ensures the list shows fresh data regardless of what happened in editor.
  Future<void> _navigateToEditor(BuildContext context, {String? noteId}) async {
    await context.push(
      '${RouteConstants.dailyNotebook}/edit',
      extra: noteId != null ? {'noteId': noteId} : <String, dynamic>{},
    );
    
    // When navigation returns (user saved, deleted, or just pressed back),
    // always reload to ensure fresh data.
    // The small delay ensures the route transition completes fully before
    // dispatching events, preventing race conditions in release builds.
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _bloc.add(const RefreshNotes());
        _bloc.add(const LoadSummary());
      }
    }
  }

  // ─── Dialogs ─────────────────────────────────────────────────

  void _showDeleteConfirmation(BuildContext context, DailyNoteModel note) {
    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                size: 48, color: AppColors.credit),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.deleteNote, style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.deleteNoteConfirm,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondaryColor),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _bloc.add(DeleteNote(note.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.credit,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteConfirmation(BuildContext context, int count) {
    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_outlined,
                size: 48, color: AppColors.credit),
            const SizedBox(height: AppSpacing.md),
            Text('Delete $count Notes?', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            Text('This action cannot be undone.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _bloc.add(const BulkDeleteSelected());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.credit,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
