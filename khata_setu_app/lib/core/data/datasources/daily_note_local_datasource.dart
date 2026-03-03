import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../hive_initializer.dart';
import '../models/daily_note_model.dart';

/// Local data source for DailyNote operations backed by Hive.
/// Serves as offline cache and primary store before remote sync.
class DailyNoteLocalDataSource {
  Box<DailyNoteModel> get _box =>
      Hive.box<DailyNoteModel>(HiveBoxes.dailyNotes);

  // ─── Create / Update ─────────────────────────────────────────

  Future<void> saveDailyNote(DailyNoteModel note) async {
    await _box.put(note.id, note);
  }

  /// Save a batch of notes (e.g. from API response).
  Future<void> saveAll(List<DailyNoteModel> notes) async {
    final map = {for (final n in notes) n.id: n};
    await _box.putAll(map);
  }

  // ─── Read ────────────────────────────────────────────────────

  DailyNoteModel? getDailyNoteById(String id) {
    return _box.get(id);
  }

  /// Get all notes, sorted by noteDate descending.
  List<DailyNoteModel> getAllNotes() {
    return _box.values
        .where((n) => !n.isDeleted)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  /// Get all notes for a customer, sorted by date descending.
  List<DailyNoteModel> getNotesForCustomer(String customerId) {
    return _box.values
        .where((n) => n.customerId == customerId && !n.isDeleted)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  /// Get note for a specific customer + date combo.
  DailyNoteModel? getNoteForCustomerDate(String customerId, DateTime date) {
    final dateKey = _dateKey(date);
    try {
      return _box.values.firstWhere(
        (n) =>
            n.customerId == customerId &&
            n.dateKey == dateKey &&
            !n.isDeleted,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get notes with local filtering, searching, and pagination.
  ({List<DailyNoteModel> notes, int totalCount}) getFilteredNotes({
    int page = 1,
    int limit = 20,
    NoteFilters filters = NoteFilters.empty,
    String? search,
  }) {
    var notes = _box.values.where((n) => !n.isDeleted);

    // Apply filters
    if (filters.customerId != null) {
      notes = notes.where((n) => n.customerId == filters.customerId);
    }
    if (filters.status != null) {
      notes = notes.where((n) => n.status == filters.status);
    }
    if (filters.priority != null) {
      notes = notes.where((n) => n.priority == filters.priority);
    }
    if (filters.tag != null) {
      notes = notes.where((n) => n.tags.contains(filters.tag));
    }
    if (filters.startDate != null) {
      final startKey = _dateKey(filters.startDate!);
      notes = notes.where((n) => n.dateKey.compareTo(startKey) >= 0);
    }
    if (filters.endDate != null) {
      final endKey = _dateKey(filters.endDate!);
      notes = notes.where((n) => n.dateKey.compareTo(endKey) <= 0);
    }

    // Apply search
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      notes = notes.where((n) =>
          n.title.toLowerCase().contains(q) ||
          (n.description?.toLowerCase().contains(q) ?? false) ||
          (n.customerName?.toLowerCase().contains(q) ?? false) ||
          n.tags.any((t) => t.toLowerCase().contains(q)) ||
          n.items.any((i) => i.productName.toLowerCase().contains(q)));
    }

    // Sort
    final sorted = notes.toList();
    final sortBy = filters.sortBy ?? 'noteDate';
    final ascending = filters.sortOrder == 'asc';
    sorted.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case 'priority':
          const order = {'high': 0, 'medium': 1, 'low': 2};
          cmp = (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1);
          break;
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        case 'totalAmount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'createdAt':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        default: // noteDate
          cmp = a.dateKey.compareTo(b.dateKey);
      }
      return ascending ? cmp : -cmp;
    });

    // Paginate
    final totalCount = sorted.length;
    final skip = (page - 1) * limit;
    final paginated = sorted.skip(skip).take(limit).toList();

    return (notes: paginated, totalCount: totalCount);
  }

  /// Get notes grouped by date key.
  Map<String, List<DailyNoteModel>> getNotesGroupedByDate(
      {String? customerId}) {
    final notes = customerId != null
        ? getNotesForCustomer(customerId)
        : getAllNotes();

    final grouped = <String, List<DailyNoteModel>>{};
    for (final note in notes) {
      grouped.putIfAbsent(note.dateKey, () => []).add(note);
    }
    return grouped;
  }

  /// Get unsynced notes (created/updated locally, not pushed to remote).
  List<DailyNoteModel> getUnsyncedNotes() {
    return _box.values.where((n) => !n.synced && !n.isDeleted).toList();
  }

  // ─── Delete ──────────────────────────────────────────────────

  Future<void> softDeleteNote(String id) async {
    final note = _box.get(id);
    if (note != null) {
      note.isDeleted = true;
      note.updatedAt = DateTime.now();
      await note.save();
    }
  }

  Future<void> hardDeleteNote(String id) async {
    await _box.delete(id);
  }

  /// Bulk soft-delete by IDs.
  Future<void> bulkSoftDelete(List<String> ids) async {
    for (final id in ids) {
      await softDeleteNote(id);
    }
  }

  /// Bulk mark as completed locally.
  Future<void> bulkComplete(List<String> ids) async {
    for (final id in ids) {
      final note = _box.get(id);
      if (note != null && note.status != 'completed') {
        note.status = 'completed';
        note.completedAt = DateTime.now();
        note.updatedAt = DateTime.now();
        await note.save();
      }
    }
  }

  // ─── Frequent Items ─────────────────────────────────────────

  /// Returns top N product names used by this customer, sorted by frequency.
  List<String> getFrequentProducts(String customerId, {int limit = 10}) {
    final notes = getNotesForCustomer(customerId);
    final freq = <String, int>{};
    for (final note in notes) {
      for (final item in note.items) {
        freq[item.productName] = (freq[item.productName] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get yesterday's note for a customer (for "repeat yesterday" feature).
  DailyNoteModel? getYesterdayNote(String customerId) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getNoteForCustomerDate(customerId, yesterday);
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
