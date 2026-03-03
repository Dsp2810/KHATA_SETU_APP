import 'package:flutter/foundation.dart';

import '../../network/api_service.dart';
import '../models/daily_note_model.dart';

/// Remote data source for daily notes backed by the backend API.
/// Handles JSON ↔ DailyNoteModel conversion.
class DailyNoteRemoteDataSource {
  final ApiService _api;
  final String _shopId;

  DailyNoteRemoteDataSource(this._api, this._shopId);

  // ─── CRUD ────────────────────────────────────────────────────

  /// Fetch paginated, filtered notes list.
  /// Returns `{ notes: [...], pagination: { page, limit, totalCount, totalPages } }`.
  Future<({List<DailyNoteModel> notes, int totalCount, int totalPages, int currentPage})>
      getNotes({
    int page = 1,
    int limit = 20,
    NoteFilters filters = NoteFilters.empty,
    String? search,
  }) async {
    try {
      final data = await _api.getNotes(
        _shopId,
        page: page,
        limit: limit,
        customerId: filters.customerId,
        status: filters.status,
        priority: filters.priority,
        tag: filters.tag,
        startDate: filters.startDate?.toIso8601String(),
        endDate: filters.endDate?.toIso8601String(),
        search: search,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
      );

      final notesList = <DailyNoteModel>[];
      if (data['notes'] != null) {
        for (final json in (data['notes'] as List)) {
          notesList.add(DailyNoteModel.fromJson(json as Map<String, dynamic>));
        }
      }

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      return (
        notes: notesList,
        totalCount: pagination['totalCount'] as int? ?? notesList.length,
        totalPages: pagination['totalPages'] as int? ?? 1,
        currentPage: pagination['page'] as int? ?? page,
      );
    } catch (e) {
      debugPrint('DailyNoteRemoteDataSource.getNotes error: $e');
      rethrow;
    }
  }

  /// Get a single note by ID.
  Future<DailyNoteModel> getNote(String noteId) async {
    final data = await _api.getNote(_shopId, noteId);
    return DailyNoteModel.fromJson(data['note'] as Map<String, dynamic>);
  }

  /// Create a new note.
  Future<DailyNoteModel> createNote(DailyNoteModel note) async {
    final data = await _api.createNote(_shopId, note.toJson());
    return DailyNoteModel.fromJson(data['note'] as Map<String, dynamic>);
  }

  /// Update an existing note.
  Future<DailyNoteModel> updateNote(
      String noteId, Map<String, dynamic> updates) async {
    final data = await _api.updateNote(_shopId, noteId, updates);
    return DailyNoteModel.fromJson(data['note'] as Map<String, dynamic>);
  }

  /// Soft-delete a note.
  Future<void> deleteNote(String noteId) async {
    await _api.deleteNote(_shopId, noteId);
  }

  // ─── Actions ─────────────────────────────────────────────────

  /// Mark a note as completed.
  Future<DailyNoteModel> completeNote(String noteId) async {
    final data = await _api.completeNote(_shopId, noteId);
    return DailyNoteModel.fromJson(data['note'] as Map<String, dynamic>);
  }

  /// Bulk mark notes as completed.
  Future<({int requested, int modified})> bulkComplete(
      List<String> noteIds) async {
    final data = await _api.bulkCompleteNotes(_shopId, noteIds);
    return (
      requested: data['requested'] as int? ?? noteIds.length,
      modified: data['modified'] as int? ?? 0,
    );
  }

  /// Bulk soft-delete notes.
  Future<({int requested, int modified})> bulkDelete(
    List<String> noteIds, {
    String? reason,
  }) async {
    final data =
        await _api.bulkDeleteNotes(_shopId, noteIds, reason: reason);
    return (
      requested: data['requested'] as int? ?? noteIds.length,
      modified: data['modified'] as int? ?? 0,
    );
  }

  // ─── Special Views ───────────────────────────────────────────

  /// Get today's notes.
  Future<List<DailyNoteModel>> getTodayNotes() async {
    final data = await _api.getTodayNotes(_shopId);
    final notesList = <DailyNoteModel>[];
    if (data['notes'] != null) {
      for (final json in (data['notes'] as List)) {
        notesList.add(DailyNoteModel.fromJson(json as Map<String, dynamic>));
      }
    }
    return notesList;
  }

  /// Get summary statistics.
  Future<NoteSummary> getSummary({
    String? startDate,
    String? endDate,
  }) async {
    final data = await _api.getNoteSummary(
      _shopId,
      startDate: startDate,
      endDate: endDate,
    );
    return NoteSummary.fromJson(
        data['summary'] as Map<String, dynamic>? ?? {});
  }
}
