import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/data/repositories/daily_note_repository.dart';
import 'daily_note_event.dart';
import 'daily_note_state.dart';

/// BLoC managing daily notes — list with pagination, search, filters,
/// single note editing, bulk operations, and summary.
class DailyNoteBloc extends Bloc<DailyNoteEvent, DailyNoteState> {
  DailyNoteRepository _noteRepo;

  static const int _pageSize = 20;

  DailyNoteBloc({
    required DailyNoteRepository noteRepository,
  })  : _noteRepo = noteRepository,
        super(const DailyNoteInitial()) {
    // List / Pagination
    on<LoadNotes>(_onLoadNotes);
    on<LoadMoreNotes>(_onLoadMore);
    on<RefreshNotes>(_onRefresh);
    on<SearchNotes>(_onSearch, transformer: _debounce());
    on<UpdateFilters>(_onUpdateFilters);
    on<ClearFilters>(_onClearFilters);

    // Single Note editing
    on<LoadNoteForEdit>(_onLoadNoteForEdit);
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<UpdateItem>(_onUpdateItem);
    on<UpdateNoteField>(_onUpdateNoteField);
    on<SaveNote>(_onSaveNote);
    on<DeleteNote>(_onDeleteNote);
    on<CompleteNote>(_onCompleteNote);
    on<RepeatYesterdayNote>(_onRepeatYesterday);

    // Bulk
    on<ToggleSelectMode>(_onToggleSelectMode);
    on<ToggleNoteSelection>(_onToggleSelection);
    on<SelectAllNotes>(_onSelectAll);
    on<BulkCompleteSelected>(_onBulkComplete);
    on<BulkDeleteSelected>(_onBulkDelete);

    // Summary
    on<LoadSummary>(_onLoadSummary);
  }

  /// Hot-swap the repository after login wires up remote datasource.
  void updateRepository(DailyNoteRepository repository) {
    _noteRepo = repository;
  }

  /// Debounce transformer for search (300ms).
  EventTransformer<T> _debounce<T>() {
    return (events, mapper) =>
        events.debounceTime(const Duration(milliseconds: 300)).flatMap(mapper);
  }

  // ═══════════════════════ List / Pagination ═══════════════════════

  Future<void> _onLoadNotes(
      LoadNotes event, Emitter<DailyNoteState> emit) async {
    emit(const DailyNoteLoading());
    try {
      final result = await _noteRepo.getNotes(
        page: 1,
        limit: _pageSize,
        filters: event.filters,
        search: event.search,
      );

      emit(DailyNotesLoaded(
        notes: result.notes,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        searchQuery: event.search ?? '',
        filters: event.filters,
      ));
    } catch (e) {
      emit(DailyNoteError('Failed to load notes: $e'));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreNotes event, Emitter<DailyNoteState> emit) async {
    final current = state;
    if (current is! DailyNotesLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    try {
      final result = await _noteRepo.getNotes(
        page: current.currentPage + 1,
        limit: _pageSize,
        filters: current.filters,
        search: current.searchQuery.isNotEmpty ? current.searchQuery : null,
      );

      emit(current.copyWith(
        notes: [...current.notes, ...result.notes],
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      debugPrint('DailyNoteBloc.loadMore error: $e');
    }
  }

  Future<void> _onRefresh(
      RefreshNotes event, Emitter<DailyNoteState> emit) async {
    final current = state;
    final filters =
        current is DailyNotesLoaded ? current.filters : NoteFilters.empty;
    final search =
        current is DailyNotesLoaded && current.searchQuery.isNotEmpty
            ? current.searchQuery
            : null;

    // ALWAYS emit loading state on refresh to ensure UI updates properly.
    // This prevents infinite loading when returning from editor where state
    // was DailyNoteSaved or DailyNoteEditing.
    emit(const DailyNoteLoading());

    try {
      final result = await _noteRepo.getNotes(
        page: 1,
        limit: _pageSize,
        filters: filters,
        search: search,
      );

      emit(DailyNotesLoaded(
        notes: result.notes,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        searchQuery: search ?? '',
        filters: filters,
      ));
    } catch (e) {
      // On error, emit empty list state so UI isn't stuck on loading.
      // NEVER leave the UI in Loading state without a follow-up emission.
      emit(DailyNotesLoaded(
        notes: const [],
        currentPage: 1,
        totalPages: 1,
        totalCount: 0,
        searchQuery: search ?? '',
        filters: filters,
      ));
      debugPrint('DailyNoteBloc.refresh error: $e');
    }
  }

  Future<void> _onSearch(
      SearchNotes event, Emitter<DailyNoteState> emit) async {
    final current = state;
    final filters =
        current is DailyNotesLoaded ? current.filters : NoteFilters.empty;
    final search = event.query.trim().isEmpty ? null : event.query.trim();

    emit(const DailyNoteLoading());

    try {
      final result = await _noteRepo.getNotes(
        page: 1,
        limit: _pageSize,
        filters: filters,
        search: search,
      );

      emit(DailyNotesLoaded(
        notes: result.notes,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        searchQuery: event.query,
        filters: filters,
      ));
    } catch (e) {
      emit(DailyNoteError('Search failed: $e'));
    }
  }

  Future<void> _onUpdateFilters(
      UpdateFilters event, Emitter<DailyNoteState> emit) async {
    final current = state;
    final search =
        current is DailyNotesLoaded && current.searchQuery.isNotEmpty
            ? current.searchQuery
            : null;

    emit(const DailyNoteLoading());

    try {
      final result = await _noteRepo.getNotes(
        page: 1,
        limit: _pageSize,
        filters: event.filters,
        search: search,
      );

      emit(DailyNotesLoaded(
        notes: result.notes,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        searchQuery: search ?? '',
        filters: event.filters,
      ));
    } catch (e) {
      emit(DailyNoteError('Filter failed: $e'));
    }
  }

  Future<void> _onClearFilters(
      ClearFilters event, Emitter<DailyNoteState> emit) async {
    add(const LoadNotes());
  }

  // ═══════════════════════ Single Note Editing ═══════════════════════

  Future<void> _onLoadNoteForEdit(
      LoadNoteForEdit event, Emitter<DailyNoteState> emit) async {
    emit(const DailyNoteLoading());
    try {
      DailyNoteModel note;
      bool isNew = true;
      List<String> frequent = [];

      if (event.noteId != null) {
        // Edit existing
        final existing = await _noteRepo.getNoteById(event.noteId!);
        if (existing == null) {
          emit(const DailyNoteError('Note not found'));
          return;
        }
        note = existing;
        isNew = false;
      } else {
        // Create new
        note = DailyNoteModel(
          customerId: event.customerId,
          customerName: event.customerName,
          noteDate: DateTime.now(),
        );
      }

      // Get frequent products if customer is set
      if (note.customerId != null && note.customerId!.isNotEmpty) {
        frequent =
            _noteRepo.getFrequentProducts(note.customerId!, limit: 15);
      }

      final hasYesterday = note.customerId != null &&
          note.customerId!.isNotEmpty &&
          _noteRepo.getYesterdayNote(note.customerId!) != null;

      emit(DailyNoteEditing(
        note: note,
        isNew: isNew,
        frequentProducts: frequent,
        hasYesterdayNote: hasYesterday,
      ));
    } catch (e) {
      emit(DailyNoteError('Failed to load note: $e'));
    }
  }

  void _onAddItem(AddItem event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNoteEditing) return;

    final updatedItems = List<DailyItemModel>.from(current.note.items)
      ..add(event.item);

    emit(current.copyWith(
      note: current.note.copyWith(items: updatedItems),
    ));
  }

  void _onRemoveItem(RemoveItem event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNoteEditing) return;

    final updatedItems =
        current.note.items.where((i) => i.id != event.itemId).toList();

    emit(current.copyWith(
      note: current.note.copyWith(items: updatedItems),
    ));
  }

  void _onUpdateItem(UpdateItem event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNoteEditing) return;

    final updatedItems = current.note.items
        .map((i) => i.id == event.updatedItem.id ? event.updatedItem : i)
        .toList();

    emit(current.copyWith(
      note: current.note.copyWith(items: updatedItems),
    ));
  }

  void _onUpdateNoteField(
      UpdateNoteField event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNoteEditing) return;

    emit(current.copyWith(
      note: current.note.copyWith(
        title: event.title,
        description: event.description,
        priority: event.priority,
        status: event.status,
        tags: event.tags,
        reminderAt: event.reminderAt,
        customerId: event.customerId,
        customerName: event.customerName,
      ),
    ));
  }

  Future<void> _onSaveNote(
      SaveNote event, Emitter<DailyNoteState> emit) async {
    final current = state;
    if (current is! DailyNoteEditing) return;

    if (current.note.title.trim().isEmpty) {
      emit(const DailyNoteError('Note title is required'));
      emit(current); // Restore editing state
      return;
    }

    emit(current.copyWith(isSaving: true));

    try {
      DailyNoteModel savedNote;

      if (current.isNew) {
        savedNote = await _noteRepo.createNote(current.note);
      } else {
        // Build updates map
        final updates = current.note.toJson();
        savedNote = await _noteRepo.updateNote(current.note.id, updates);
      }

      // Emit saved state - this will trigger navigation pop in the editor
      emit(DailyNoteSaved(
        note: savedNote,
        ledgerEntryCreated: event.createLedgerEntry,
      ));
      
      // After emitting DailyNoteSaved, immediately transition to DailyNoteInitial
      // so the list page's RefreshNotes has a clean state to work with.
      // This prevents any race conditions with state checks.
      emit(const DailyNoteInitial());
    } catch (e) {
      debugPrint('DailyNoteBloc.save error: $e');
      emit(DailyNoteError('Failed to save: $e'));
      emit(current.copyWith(isSaving: false));
    }
  }

  Future<void> _onDeleteNote(
      DeleteNote event, Emitter<DailyNoteState> emit) async {
    try {
      await _noteRepo.deleteNote(event.noteId);
      emit(const DailyNoteDeleted());
      // Reset to initial state so RefreshNotes works cleanly
      emit(const DailyNoteInitial());
    } catch (e) {
      emit(DailyNoteError('Failed to delete: $e'));
    }
  }

  Future<void> _onCompleteNote(
      CompleteNote event, Emitter<DailyNoteState> emit) async {
    final current = state;
    if (current is! DailyNotesLoaded) return;

    try {
      await _noteRepo.completeNote(event.noteId);

      // Update the note in the local list
      final updatedNotes = current.notes.map((n) {
        if (n.id == event.noteId) {
          return n.copyWith(
            status: 'completed',
            completedAt: DateTime.now(),
          );
        }
        return n;
      }).toList();

      emit(current.copyWith(notes: updatedNotes));
    } catch (e) {
      emit(DailyNoteError('Failed to complete: $e'));
      emit(current); // Restore loaded state
    }
  }

  void _onRepeatYesterday(
      RepeatYesterdayNote event, Emitter<DailyNoteState> emit) {
    try {
      final repeated = _noteRepo.repeatYesterdayNote(event.customerId);
      if (repeated == null) {
        emit(const DailyNoteError('No items from yesterday to repeat'));
        return;
      }

      final frequent =
          _noteRepo.getFrequentProducts(event.customerId, limit: 15);

      emit(DailyNoteEditing(
        note: repeated,
        isNew: true,
        frequentProducts: frequent,
        hasYesterdayNote: false,
      ));
    } catch (e) {
      emit(DailyNoteError('Failed to repeat yesterday: $e'));
    }
  }

  // ═══════════════════════ Bulk Operations ═══════════════════════

  void _onToggleSelectMode(
      ToggleSelectMode event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNotesLoaded) return;

    emit(current.copyWith(
      isSelectMode: !current.isSelectMode,
      selectedNoteIds: {}, // Clear selection on toggle
    ));
  }

  void _onToggleSelection(
      ToggleNoteSelection event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNotesLoaded) return;

    final selected = Set<String>.from(current.selectedNoteIds);
    if (selected.contains(event.noteId)) {
      selected.remove(event.noteId);
    } else {
      selected.add(event.noteId);
    }

    emit(current.copyWith(selectedNoteIds: selected));
  }

  void _onSelectAll(SelectAllNotes event, Emitter<DailyNoteState> emit) {
    final current = state;
    if (current is! DailyNotesLoaded) return;

    final allIds = current.notes.map((n) => n.id).toSet();
    final allSelected = current.selectedNoteIds.length == allIds.length;

    emit(current.copyWith(
      selectedNoteIds: allSelected ? {} : allIds,
    ));
  }

  Future<void> _onBulkComplete(
      BulkCompleteSelected event, Emitter<DailyNoteState> emit) async {
    final current = state;
    if (current is! DailyNotesLoaded || current.selectedNoteIds.isEmpty) return;

    final ids = current.selectedNoteIds.toList();

    try {
      final result = await _noteRepo.bulkComplete(ids);

      emit(DailyNoteBulkActionDone(
        message: '${result.modified} notes completed',
        modified: result.modified,
      ));

      // Reload the list
      add(LoadNotes(filters: current.filters, search: current.searchQuery.isNotEmpty ? current.searchQuery : null));
    } catch (e) {
      emit(DailyNoteError('Bulk complete failed: $e'));
      emit(current);
    }
  }

  Future<void> _onBulkDelete(
      BulkDeleteSelected event, Emitter<DailyNoteState> emit) async {
    final current = state;
    if (current is! DailyNotesLoaded || current.selectedNoteIds.isEmpty) return;

    final ids = current.selectedNoteIds.toList();

    try {
      final result =
          await _noteRepo.bulkDelete(ids, reason: event.reason);

      emit(DailyNoteBulkActionDone(
        message: '${result.modified} notes deleted',
        modified: result.modified,
      ));

      // Reload the list
      add(LoadNotes(filters: current.filters, search: current.searchQuery.isNotEmpty ? current.searchQuery : null));
    } catch (e) {
      emit(DailyNoteError('Bulk delete failed: $e'));
      emit(current);
    }
  }

  // ═══════════════════════ Summary ═══════════════════════

  Future<void> _onLoadSummary(
      LoadSummary event, Emitter<DailyNoteState> emit) async {
    final current = state;

    try {
      final summary = await _noteRepo.getSummary();

      if (current is DailyNotesLoaded) {
        emit(current.copyWith(summary: summary));
      }
    } catch (e) {
      debugPrint('DailyNoteBloc.loadSummary error: $e');
    }
  }
}
