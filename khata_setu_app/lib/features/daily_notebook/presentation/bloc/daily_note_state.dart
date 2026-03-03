import 'package:equatable/equatable.dart';

import '../../../../core/data/models/daily_note_model.dart';

abstract class DailyNoteState extends Equatable {
  const DailyNoteState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class DailyNoteInitial extends DailyNoteState {
  const DailyNoteInitial();
}

/// Full loading (first load or filter change).
class DailyNoteLoading extends DailyNoteState {
  const DailyNoteLoading();
}

/// State when viewing the paginated, filterable list of daily notes.
class DailyNotesLoaded extends DailyNoteState {
  final List<DailyNoteModel> notes;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool isLoadingMore;
  final String searchQuery;
  final NoteFilters filters;
  final Set<String> selectedNoteIds;
  final bool isSelectMode;
  final NoteSummary? summary;

  const DailyNotesLoaded({
    required this.notes,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filters = NoteFilters.empty,
    this.selectedNoteIds = const {},
    this.isSelectMode = false,
    this.summary,
  });

  bool get hasMore => currentPage < totalPages;

  double get grandTotal =>
      notes.fold(0.0, (sum, n) => sum + n.totalAmount);

  int get selectedCount => selectedNoteIds.length;

  bool isSelected(String noteId) => selectedNoteIds.contains(noteId);

  DailyNotesLoaded copyWith({
    List<DailyNoteModel>? notes,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? isLoadingMore,
    String? searchQuery,
    NoteFilters? filters,
    Set<String>? selectedNoteIds,
    bool? isSelectMode,
    NoteSummary? summary,
  }) {
    return DailyNotesLoaded(
      notes: notes ?? this.notes,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
      isSelectMode: isSelectMode ?? this.isSelectMode,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [
        notes,
        currentPage,
        totalPages,
        totalCount,
        isLoadingMore,
        searchQuery,
        filters,
        selectedNoteIds,
        isSelectMode,
        summary,
      ];
}

/// State when editing a single note (create or update).
class DailyNoteEditing extends DailyNoteState {
  final DailyNoteModel note;
  final bool isNew;
  final List<String> frequentProducts;
  final bool hasYesterdayNote;
  final bool isSaving;

  const DailyNoteEditing({
    required this.note,
    this.isNew = true,
    this.frequentProducts = const [],
    this.hasYesterdayNote = false,
    this.isSaving = false,
  });

  double get totalAmount => note.totalAmount;
  int get itemCount => note.itemCount;

  DailyNoteEditing copyWith({
    DailyNoteModel? note,
    bool? isNew,
    List<String>? frequentProducts,
    bool? hasYesterdayNote,
    bool? isSaving,
  }) {
    return DailyNoteEditing(
      note: note ?? this.note,
      isNew: isNew ?? this.isNew,
      frequentProducts: frequentProducts ?? this.frequentProducts,
      hasYesterdayNote: hasYesterdayNote ?? this.hasYesterdayNote,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Props includes all changing note fields to ensure proper state comparison.
  /// DailyNoteModel.== only compares id (for Hive), so we must compare fields directly.
  @override
  List<Object?> get props => [
        note.id,
        note.title,
        note.description,
        note.customerId,
        note.customerName,
        note.priority,
        note.status,
        note.tags,
        note.items.length,
        note.totalAmount,
        note.updatedAt,
        isNew,
        frequentProducts,
        hasYesterdayNote,
        isSaving,
      ];
}

/// Transient state after a note is saved successfully.
class DailyNoteSaved extends DailyNoteState {
  final DailyNoteModel note;
  final bool ledgerEntryCreated;

  const DailyNoteSaved({
    required this.note,
    this.ledgerEntryCreated = false,
  });

  @override
  List<Object?> get props => [note, ledgerEntryCreated];
}

/// Transient state after a note is deleted.
class DailyNoteDeleted extends DailyNoteState {
  const DailyNoteDeleted();
}

/// Transient state after bulk action completes.
class DailyNoteBulkActionDone extends DailyNoteState {
  final String message;
  final int modified;

  const DailyNoteBulkActionDone({
    required this.message,
    required this.modified,
  });

  @override
  List<Object?> get props => [message, modified];
}

/// Error state.
class DailyNoteError extends DailyNoteState {
  final String message;
  const DailyNoteError(this.message);

  @override
  List<Object?> get props => [message];
}
