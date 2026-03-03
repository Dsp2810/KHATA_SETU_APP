import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../datasources/daily_note_local_datasource.dart';
import '../datasources/daily_note_remote_datasource.dart';
import '../models/daily_note_model.dart';

/// Repository for daily notes with offline-first pattern.
///
/// When remote is available: fetches from API → caches locally → returns.
/// When offline: serves from local Hive cache.
/// Unsynced local changes are queued for later push.
class DailyNoteRepository {
  final DailyNoteLocalDataSource _local;
  final DailyNoteRemoteDataSource? _remote;

  DailyNoteRepository(this._local, [this._remote]);

  bool get hasRemote => _remote != null;

  // ─── Read (list / paginated) ─────────────────────────────────

  /// Fetch notes with pagination, filters, and search.
  /// Remote-first with local fallback.
  Future<({List<DailyNoteModel> notes, int totalCount, int totalPages, int currentPage})>
      getNotes({
    int page = 1,
    int limit = 20,
    NoteFilters filters = NoteFilters.empty,
    String? search,
  }) async {
    if (_remote != null) {
      try {
        final result = await _remote.getNotes(
          page: page,
          limit: limit,
          filters: filters,
          search: search,
        );

        // Cache fetched notes locally
        await _local.saveAll(result.notes);

        return result;
      } catch (e) {
        debugPrint('DailyNoteRepository.getNotes remote failed: $e');
        // Fall through to local
      }
    }

    // Local fallback
    final local = _local.getFilteredNotes(
      page: page,
      limit: limit,
      filters: filters,
      search: search,
    );
    return (
      notes: local.notes,
      totalCount: local.totalCount,
      totalPages: (local.totalCount / limit).ceil(),
      currentPage: page,
    );
  }

  /// Get a single note by ID.
  Future<DailyNoteModel?> getNoteById(String id) async {
    if (_remote != null) {
      try {
        final note = await _remote.getNote(id);
        await _local.saveDailyNote(note);
        return note;
      } catch (e) {
        debugPrint('DailyNoteRepository.getNoteById remote failed: $e');
      }
    }
    return _local.getDailyNoteById(id);
  }

  /// Get today's notes.
  Future<List<DailyNoteModel>> getTodayNotes() async {
    if (_remote != null) {
      try {
        final notes = await _remote.getTodayNotes();
        await _local.saveAll(notes);
        return notes;
      } catch (e) {
        debugPrint('DailyNoteRepository.getTodayNotes remote failed: $e');
      }
    }

    // Fallback: filter local notes for today
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _local
        .getAllNotes()
        .where((n) => n.dateKey == todayKey)
        .toList();
  }

  /// Get summary statistics.
  Future<NoteSummary> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_remote != null) {
      try {
        return await _remote.getSummary(
          startDate: startDate?.toIso8601String(),
          endDate: endDate?.toIso8601String(),
        );
      } catch (e) {
        debugPrint('DailyNoteRepository.getSummary remote failed: $e');
      }
    }

    // Local summary approximation
    final allNotes = _local.getAllNotes();
    return NoteSummary(
      total: allNotes.length,
      pending: allNotes.where((n) => n.status == 'pending').length,
      completed: allNotes.where((n) => n.status == 'completed').length,
      cancelled: allNotes.where((n) => n.status == 'cancelled').length,
      highPriority: allNotes.where((n) => n.priority == 'high').length,
      totalAmount:
          allNotes.fold(0.0, (sum, n) => sum + n.totalAmount),
      todayTotal: allNotes
          .where((n) =>
              n.dateKey ==
              DateFormat('yyyy-MM-dd').format(DateTime.now()))
          .length,
    );
  }

  // ─── Create ──────────────────────────────────────────────────

  /// Create and save a new note.
  /// If remote is available, sends to API first; otherwise saves locally.
  Future<DailyNoteModel> createNote(DailyNoteModel note) async {
    if (note.title.trim().isEmpty) {
      throw ArgumentError('Note title is required');
    }

    // Clean items
    final validItems = note.items
        .where((i) =>
            i.quantity > 0 &&
            i.unitPrice >= 0 &&
            i.productName.trim().isNotEmpty)
        .toList();

    final prepared = note.copyWith(
      items: validItems,
      updatedAt: DateTime.now(),
      offlineId: note.offlineId ?? note.id,
    );

    if (_remote != null) {
      try {
        final created = await _remote.createNote(prepared);
        await _local.saveDailyNote(created);
        return created;
      } catch (e) {
        debugPrint('DailyNoteRepository.createNote remote failed: $e');
        // Save locally as unsynced
        final unsynced = prepared.copyWith(synced: false);
        await _local.saveDailyNote(unsynced);
        return unsynced;
      }
    }

    // Local only
    final localNote = prepared.copyWith(synced: false);
    await _local.saveDailyNote(localNote);
    return localNote;
  }

  /// Save/update a note locally (for in-progress edits before final save).
  Future<DailyNoteModel> saveLocally(DailyNoteModel note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _local.saveDailyNote(updated);
    return updated;
  }

  // ─── Update ──────────────────────────────────────────────────

  /// Update an existing note.
  Future<DailyNoteModel> updateNote(
    String noteId,
    Map<String, dynamic> updates,
  ) async {
    if (_remote != null) {
      try {
        final updated = await _remote.updateNote(noteId, updates);
        await _local.saveDailyNote(updated);
        return updated;
      } catch (e) {
        debugPrint('DailyNoteRepository.updateNote remote failed: $e');
      }
    }

    // Local fallback
    final existing = _local.getDailyNoteById(noteId);
    if (existing == null) throw ArgumentError('Note not found');

    final updated = existing.copyWith(
      title: updates['title'] as String? ?? existing.title,
      description: updates['description'] as String? ?? existing.description,
      priority: updates['priority'] as String? ?? existing.priority,
      status: updates['status'] as String? ?? existing.status,
      tags: (updates['tags'] as List?)?.cast<String>() ?? existing.tags,
      synced: false,
      updatedAt: DateTime.now(),
    );
    await _local.saveDailyNote(updated);
    return updated;
  }

  // ─── Delete ──────────────────────────────────────────────────

  /// Delete a note (soft delete).
  Future<void> deleteNote(String noteId) async {
    if (_remote != null) {
      try {
        await _remote.deleteNote(noteId);
      } catch (e) {
        debugPrint('DailyNoteRepository.deleteNote remote failed: $e');
      }
    }
    await _local.softDeleteNote(noteId);
  }

  // ─── Actions ─────────────────────────────────────────────────

  /// Mark a note as completed.
  Future<DailyNoteModel?> completeNote(String noteId) async {
    if (_remote != null) {
      try {
        final completed = await _remote.completeNote(noteId);
        await _local.saveDailyNote(completed);
        return completed;
      } catch (e) {
        debugPrint('DailyNoteRepository.completeNote remote failed: $e');
      }
    }

    // Local fallback
    final note = _local.getDailyNoteById(noteId);
    if (note == null) return null;
    final updated = note.copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
      synced: false,
    );
    await _local.saveDailyNote(updated);
    return updated;
  }

  /// Bulk complete notes.
  Future<({int requested, int modified})> bulkComplete(
      List<String> noteIds) async {
    if (_remote != null) {
      try {
        final result = await _remote.bulkComplete(noteIds);
        // Update local cache
        await _local.bulkComplete(noteIds);
        return result;
      } catch (e) {
        debugPrint('DailyNoteRepository.bulkComplete remote failed: $e');
      }
    }

    // Local fallback
    await _local.bulkComplete(noteIds);
    return (requested: noteIds.length, modified: noteIds.length);
  }

  /// Bulk delete notes.
  Future<({int requested, int modified})> bulkDelete(
    List<String> noteIds, {
    String? reason,
  }) async {
    if (_remote != null) {
      try {
        final result =
            await _remote.bulkDelete(noteIds, reason: reason);
        await _local.bulkSoftDelete(noteIds);
        return result;
      } catch (e) {
        debugPrint('DailyNoteRepository.bulkDelete remote failed: $e');
      }
    }

    // Local fallback
    await _local.bulkSoftDelete(noteIds);
    return (requested: noteIds.length, modified: noteIds.length);
  }

  // ─── Frequent Items & Helpers ────────────────────────────────

  List<String> getFrequentProducts(String customerId, {int limit = 10}) =>
      _local.getFrequentProducts(customerId, limit: limit);

  DailyNoteModel? getYesterdayNote(String customerId) =>
      _local.getYesterdayNote(customerId);

  /// Create a copy of yesterday's note for today.
  DailyNoteModel? repeatYesterdayNote(String customerId) {
    final yesterday = _local.getYesterdayNote(customerId);
    if (yesterday == null) return null;

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check if today already has a note for this customer
    final existing = _local.getNoteForCustomerDate(
      customerId,
      DateTime.now(),
    );
    if (existing != null) return existing;

    // Clone yesterday's items with fresh IDs
    final clonedItems = yesterday.items
        .map((item) => DailyItemModel(
              productName: item.productName,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              unit: item.unit,
              timeLabel: item.timeLabel,
              productId: item.productId,
            ))
        .toList();

    return DailyNoteModel(
      title: yesterday.title,
      customerId: customerId,
      customerName: yesterday.customerName,
      customerPhone: yesterday.customerPhone,
      dateKey: todayKey,
      noteDate: DateTime.now(),
      items: clonedItems,
      description: yesterday.description,
      priority: yesterday.priority,
      tags: List<String>.from(yesterday.tags),
    );
  }

  /// Get unsynced local notes for push to remote.
  List<DailyNoteModel> getUnsyncedNotes() =>
      _local.getUnsyncedNotes();
}
