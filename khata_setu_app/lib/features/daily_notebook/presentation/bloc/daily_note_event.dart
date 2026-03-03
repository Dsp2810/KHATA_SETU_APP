import 'package:equatable/equatable.dart';

import '../../../../core/data/models/daily_note_model.dart';

abstract class DailyNoteEvent extends Equatable {
  const DailyNoteEvent();

  @override
  List<Object?> get props => [];
}

// ─── List / Pagination ─────────────────────────────────────────

/// Load notes (first page) with optional filters and search.
class LoadNotes extends DailyNoteEvent {
  final NoteFilters filters;
  final String? search;

  const LoadNotes({
    this.filters = NoteFilters.empty,
    this.search,
  });

  @override
  List<Object?> get props => [filters, search];
}

/// Load the next page (infinite scroll).
class LoadMoreNotes extends DailyNoteEvent {
  const LoadMoreNotes();
}

/// Refresh (pull-to-refresh) — reloads page 1 with current filters.
class RefreshNotes extends DailyNoteEvent {
  const RefreshNotes();
}

/// Update search query with debounce handled in BLoC.
class SearchNotes extends DailyNoteEvent {
  final String query;
  const SearchNotes(this.query);

  @override
  List<Object?> get props => [query];
}

/// Apply filter changes.
class UpdateFilters extends DailyNoteEvent {
  final NoteFilters filters;
  const UpdateFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

/// Clear all active filters.
class ClearFilters extends DailyNoteEvent {
  const ClearFilters();
}

// ─── Single Note ───────────────────────────────────────────────

/// Load a note for editing (existing or create new).
class LoadNoteForEdit extends DailyNoteEvent {
  final String? noteId;
  final String? customerId;
  final String? customerName;

  const LoadNoteForEdit({
    this.noteId,
    this.customerId,
    this.customerName,
  });

  @override
  List<Object?> get props => [noteId, customerId, customerName];
}

/// Add a new item row to the editing note.
class AddItem extends DailyNoteEvent {
  final DailyItemModel item;
  const AddItem(this.item);

  @override
  List<Object?> get props => [item];
}

/// Remove an item row by its id.
class RemoveItem extends DailyNoteEvent {
  final String itemId;
  const RemoveItem(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Update an item row.
class UpdateItem extends DailyNoteEvent {
  final DailyItemModel updatedItem;
  const UpdateItem(this.updatedItem);

  @override
  List<Object?> get props => [updatedItem];
}

/// Update in-memory note fields (title, description, priority, tags, etc.).
class UpdateNoteField extends DailyNoteEvent {
  final String? title;
  final String? description;
  final String? priority;
  final String? status;
  final List<String>? tags;
  final DateTime? reminderAt;
  final String? customerId;
  final String? customerName;

  const UpdateNoteField({
    this.title,
    this.description,
    this.priority,
    this.status,
    this.tags,
    this.reminderAt,
    this.customerId,
    this.customerName,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        priority,
        status,
        tags,
        reminderAt,
        customerId,
        customerName,
      ];
}

/// Save the note (create or update via API).
class SaveNote extends DailyNoteEvent {
  final bool createLedgerEntry;
  const SaveNote({this.createLedgerEntry = false});

  @override
  List<Object?> get props => [createLedgerEntry];
}

/// Delete a single note.
class DeleteNote extends DailyNoteEvent {
  final String noteId;
  const DeleteNote(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

/// Mark a single note as completed.
class CompleteNote extends DailyNoteEvent {
  final String noteId;
  const CompleteNote(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// ─── Bulk Operations ───────────────────────────────────────────

/// Toggle multi-select mode.
class ToggleSelectMode extends DailyNoteEvent {
  const ToggleSelectMode();
}

/// Toggle selection of a single note.
class ToggleNoteSelection extends DailyNoteEvent {
  final String noteId;
  const ToggleNoteSelection(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

/// Select all visible notes.
class SelectAllNotes extends DailyNoteEvent {
  const SelectAllNotes();
}

/// Bulk complete selected notes.
class BulkCompleteSelected extends DailyNoteEvent {
  const BulkCompleteSelected();
}

/// Bulk delete selected notes.
class BulkDeleteSelected extends DailyNoteEvent {
  final String? reason;
  const BulkDeleteSelected({this.reason});

  @override
  List<Object?> get props => [reason];
}

// ─── Summary ───────────────────────────────────────────────────

/// Load summary statistics.
class LoadSummary extends DailyNoteEvent {
  const LoadSummary();
}

// ─── Repeat Yesterday ──────────────────────────────────────────

/// Repeat yesterday's note for a customer.
class RepeatYesterdayNote extends DailyNoteEvent {
  final String customerId;
  const RepeatYesterdayNote(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
