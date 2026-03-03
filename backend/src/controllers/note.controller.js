const { DailyNote, Customer, Product } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');
const mongoose = require('mongoose');

// ─────────────────────────────────────────────────────────────
// Helper: validate cross-shop ownership of customer & products
// ─────────────────────────────────────────────────────────────

async function validateRelations(shopId, body) {
  // Validate customerId belongs to this shop
  if (body.customerId) {
    const customer = await Customer.findOne({
      _id: body.customerId,
      shopId,
      isActive: true,
    }).select('_id').lean();

    if (!customer) {
      throw new AppError(
        'Customer not found or does not belong to this shop',
        404,
        'CUSTOMER_NOT_FOUND'
      );
    }
  }

  // Validate all productIds in structuredItems belong to this shop
  if (body.structuredItems && body.structuredItems.length > 0) {
    const productIds = body.structuredItems
      .filter((item) => item.productId)
      .map((item) => item.productId);

    if (productIds.length > 0) {
      const uniqueIds = [...new Set(productIds)];
      const products = await Product.find({
        _id: { $in: uniqueIds },
        shopId,
        isActive: true,
      })
        .select('_id name sellingPrice')
        .lean();

      if (products.length !== uniqueIds.length) {
        const foundIds = new Set(products.map((p) => p._id.toString()));
        const missing = uniqueIds.filter((id) => !foundIds.has(id));
        throw new AppError(
          `Products not found or don't belong to this shop: ${missing.join(', ')}`,
          404,
          'PRODUCT_NOT_FOUND'
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// CREATE NOTE
// POST /api/v1/shops/:shopId/notes
// ─────────────────────────────────────────────────────────────

const createNote = asyncHandler(async (req, res) => {
  const { shopId } = req.params;

  await validateRelations(shopId, req.body);

  const noteData = {
    ...req.body,
    shopId,
    createdBy: req.userId,
  };

  const note = await DailyNote.create(noteData);

  // Populate for response
  await note.populate([
    { path: 'customerId', select: 'name phone currentBalance' },
    { path: 'structuredItems.productId', select: 'name sellingPrice unit' },
    { path: 'createdBy', select: 'name' },
  ]);

  auditLog('NOTE_CREATED', req.userId, {
    noteId: note._id,
    shopId,
    customerId: req.body.customerId || null,
  });

  res.status(201).json({
    success: true,
    message: 'Note created successfully',
    data: { note },
  });
});

// ─────────────────────────────────────────────────────────────
// GET ALL NOTES (filtered, paginated)
// GET /api/v1/shops/:shopId/notes
// ─────────────────────────────────────────────────────────────

const getNotes = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const {
    customerId,
    status,
    priority,
    tag,
    startDate,
    endDate,
    search,
    sortBy,
    sortOrder,
    page,
    limit,
  } = req.query;

  // Build query
  const query = {
    shopId: new mongoose.Types.ObjectId(shopId),
    isDeleted: false,
  };

  if (customerId) {
    query.customerId = new mongoose.Types.ObjectId(customerId);
  }

  if (status) {
    query.status = status;
  }

  if (priority) {
    query.priority = priority;
  }

  if (tag) {
    query.tags = tag; // Mongoose matches element in array
  }

  if (startDate || endDate) {
    query.noteDate = {};
    if (startDate) query.noteDate.$gte = new Date(startDate);
    if (endDate) query.noteDate.$lte = new Date(endDate);
  }

  // Text search
  if (search) {
    query.$text = { $search: search };
  }

  // Sort
  const sort = {};
  if (search && !sortBy) {
    // Relevance sort for text search
    sort.score = { $meta: 'textScore' };
  }
  sort[sortBy || 'noteDate'] = sortOrder === 'asc' ? 1 : -1;

  // Pagination
  const pageNum = parseInt(page, 10) || 1;
  const pageSize = Math.min(parseInt(limit, 10) || 20, 100);
  const skip = (pageNum - 1) * pageSize;

  // Execute query + count in parallel
  const [notes, totalCount] = await Promise.all([
    DailyNote.find(query)
      .populate('customerId', 'name phone currentBalance')
      .populate('structuredItems.productId', 'name sellingPrice unit')
      .populate('createdBy', 'name')
      .sort(sort)
      .skip(skip)
      .limit(pageSize)
      .lean(),
    DailyNote.countDocuments(query),
  ]);

  res.json({
    success: true,
    data: {
      notes,
      pagination: {
        page: pageNum,
        limit: pageSize,
        totalCount,
        totalPages: Math.ceil(totalCount / pageSize),
      },
    },
  });
});

// ─────────────────────────────────────────────────────────────
// GET SINGLE NOTE
// GET /api/v1/shops/:shopId/notes/:noteId
// ─────────────────────────────────────────────────────────────

const getNote = asyncHandler(async (req, res) => {
  const { shopId, noteId } = req.params;

  const note = await DailyNote.findOne({
    _id: noteId,
    shopId,
    isDeleted: false,
  })
    .populate('customerId', 'name phone currentBalance')
    .populate('structuredItems.productId', 'name sellingPrice unit')
    .populate('createdBy', 'name')
    .populate('completedBy', 'name');

  if (!note) {
    throw new AppError('Note not found', 404, 'NOTE_NOT_FOUND');
  }

  res.json({
    success: true,
    data: { note },
  });
});

// ─────────────────────────────────────────────────────────────
// UPDATE NOTE
// PATCH /api/v1/shops/:shopId/notes/:noteId
// ─────────────────────────────────────────────────────────────

const updateNote = asyncHandler(async (req, res) => {
  const { shopId, noteId } = req.params;

  // Validate relations if customer or products are being changed
  await validateRelations(shopId, req.body);

  // If structuredItems provided, recalculate totalAmount
  const updateData = {
    ...req.body,
    modifiedBy: req.userId,
  };

  if (updateData.structuredItems && updateData.structuredItems.length > 0) {
    updateData.totalAmount = +(
      updateData.structuredItems.reduce((sum, item) => {
        item.total = +(item.quantity * item.unitPrice).toFixed(2);
        return sum + item.total;
      }, 0)
    ).toFixed(2);
  }

  const note = await DailyNote.findOneAndUpdate(
    { _id: noteId, shopId, isDeleted: false },
    updateData,
    { new: true, runValidators: true }
  )
    .populate('customerId', 'name phone currentBalance')
    .populate('structuredItems.productId', 'name sellingPrice unit')
    .populate('createdBy', 'name');

  if (!note) {
    throw new AppError('Note not found', 404, 'NOTE_NOT_FOUND');
  }

  auditLog('NOTE_UPDATED', req.userId, {
    noteId,
    shopId,
    updates: Object.keys(req.body),
  });

  res.json({
    success: true,
    message: 'Note updated successfully',
    data: { note },
  });
});

// ─────────────────────────────────────────────────────────────
// DELETE NOTE (soft)
// DELETE /api/v1/shops/:shopId/notes/:noteId
// ─────────────────────────────────────────────────────────────

const deleteNote = asyncHandler(async (req, res) => {
  const { shopId, noteId } = req.params;

  const note = await DailyNote.findOneAndUpdate(
    { _id: noteId, shopId, isDeleted: false },
    {
      isDeleted: true,
      deletedAt: new Date(),
      deletedBy: req.userId,
    },
    { new: true }
  );

  if (!note) {
    throw new AppError('Note not found', 404, 'NOTE_NOT_FOUND');
  }

  auditLog('NOTE_DELETED', req.userId, { noteId, shopId });

  res.json({
    success: true,
    message: 'Note deleted successfully',
  });
});

// ─────────────────────────────────────────────────────────────
// MARK AS COMPLETED
// POST /api/v1/shops/:shopId/notes/:noteId/complete
// ─────────────────────────────────────────────────────────────

const completeNote = asyncHandler(async (req, res) => {
  const { shopId, noteId } = req.params;

  const note = await DailyNote.findOneAndUpdate(
    {
      _id: noteId,
      shopId,
      isDeleted: false,
      status: { $ne: 'completed' },
    },
    {
      status: 'completed',
      completedAt: new Date(),
      completedBy: req.userId,
    },
    { new: true }
  )
    .populate('customerId', 'name phone')
    .populate('createdBy', 'name');

  if (!note) {
    throw new AppError(
      'Note not found or already completed',
      404,
      'NOTE_NOT_FOUND'
    );
  }

  auditLog('NOTE_COMPLETED', req.userId, { noteId, shopId });

  res.json({
    success: true,
    message: 'Note marked as completed',
    data: { note },
  });
});

// ─────────────────────────────────────────────────────────────
// BULK COMPLETE
// POST /api/v1/shops/:shopId/notes/bulk-complete
// ─────────────────────────────────────────────────────────────

const bulkComplete = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { noteIds } = req.body;

  const result = await DailyNote.updateMany(
    {
      _id: { $in: noteIds },
      shopId,
      isDeleted: false,
      status: { $ne: 'completed' },
    },
    {
      status: 'completed',
      completedAt: new Date(),
      completedBy: req.userId,
    }
  );

  auditLog('NOTES_BULK_COMPLETED', req.userId, {
    shopId,
    requested: noteIds.length,
    modified: result.modifiedCount,
  });

  res.json({
    success: true,
    message: `${result.modifiedCount} of ${noteIds.length} notes marked as completed`,
    data: {
      requested: noteIds.length,
      modified: result.modifiedCount,
      matched: result.matchedCount,
    },
  });
});

// ─────────────────────────────────────────────────────────────
// BULK DELETE
// POST /api/v1/shops/:shopId/notes/bulk-delete
// ─────────────────────────────────────────────────────────────

const bulkDelete = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { noteIds, reason } = req.body;

  const result = await DailyNote.updateMany(
    {
      _id: { $in: noteIds },
      shopId,
      isDeleted: false,
    },
    {
      isDeleted: true,
      deletedAt: new Date(),
      deletedBy: req.userId,
      ...(reason && { description: `[Deleted] ${reason}` }),
    }
  );

  auditLog('NOTES_BULK_DELETED', req.userId, {
    shopId,
    requested: noteIds.length,
    modified: result.modifiedCount,
    reason,
  });

  res.json({
    success: true,
    message: `${result.modifiedCount} of ${noteIds.length} notes deleted`,
    data: {
      requested: noteIds.length,
      modified: result.modifiedCount,
      matched: result.matchedCount,
    },
  });
});

// ─────────────────────────────────────────────────────────────
// GET TODAY'S NOTES
// GET /api/v1/shops/:shopId/notes/today
// ─────────────────────────────────────────────────────────────

const getTodayNotes = asyncHandler(async (req, res) => {
  const { shopId } = req.params;

  const notes = await DailyNote.getTodayNotes(shopId);

  res.json({
    success: true,
    data: { notes, count: notes.length },
  });
});

// ─────────────────────────────────────────────────────────────
// GET SUMMARY
// GET /api/v1/shops/:shopId/notes/summary
// ─────────────────────────────────────────────────────────────

const getNoteSummary = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { startDate, endDate } = req.query;

  const summaryResult = await DailyNote.getSummary(shopId, startDate, endDate);

  const summary = summaryResult[0] || {
    total: 0,
    pending: 0,
    completed: 0,
    cancelled: 0,
    highPriority: 0,
    totalAmount: 0,
    withCustomer: 0,
  };

  // Also get today's count
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  const todayCount = await DailyNote.countDocuments({
    shopId,
    isDeleted: false,
    noteDate: { $gte: startOfDay, $lte: endOfDay },
  });

  const todayPending = await DailyNote.countDocuments({
    shopId,
    isDeleted: false,
    status: 'pending',
    noteDate: { $gte: startOfDay, $lte: endOfDay },
  });

  res.json({
    success: true,
    data: {
      summary: {
        ...summary,
        todayTotal: todayCount,
        todayPending,
      },
    },
  });
});

module.exports = {
  createNote,
  getNotes,
  getNote,
  updateNote,
  deleteNote,
  completeNote,
  bulkComplete,
  bulkDelete,
  getTodayNotes,
  getNoteSummary,
};
