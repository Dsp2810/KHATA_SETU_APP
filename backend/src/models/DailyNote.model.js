const mongoose = require('mongoose');

/**
 * Structured item sub-schema
 * Represents a product line-item within a note
 * e.g. "3 packets biscuits × ₹10 = ₹30"
 */
const structuredItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      default: null,
    },
    productName: {
      type: String,
      trim: true,
      maxlength: [200, 'Product name cannot exceed 200 characters'],
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: [0.01, 'Quantity must be greater than 0'],
    },
    unit: {
      type: String,
      enum: ['piece', 'kg', 'gram', 'liter', 'ml', 'meter', 'dozen', 'packet', 'box', 'bundle', 'other'],
      default: 'piece',
    },
    unitPrice: {
      type: Number,
      required: [true, 'Unit price is required'],
      min: [0, 'Unit price cannot be negative'],
    },
    total: {
      type: Number,
      min: [0, 'Total cannot be negative'],
    },
  },
  { _id: false }
);

// Auto-calculate total before validation
structuredItemSchema.pre('validate', function (next) {
  this.total = +(this.quantity * this.unitPrice).toFixed(2);
  next();
});

/**
 * DailyNote Schema
 * 
 * Represents daily notes / to-do items for shopkeepers.
 * Can be attached to a customer, product, both, or standalone.
 * 
 * Examples:
 *   "Customer Dhaval: Morning 3 packets biscuits × 10"
 *   "Restock dal before weekend"
 *   "Follow up with Ramesh on payment"
 */
const dailyNoteSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: [true, 'Shop ID is required'],
    },
    title: {
      type: String,
      required: [true, 'Note title is required'],
      trim: true,
      minlength: [1, 'Title must be at least 1 character'],
      maxlength: [300, 'Title cannot exceed 300 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [5000, 'Description cannot exceed 5000 characters'],
      default: '',
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      default: null,
    },
    structuredItems: {
      type: [structuredItemSchema],
      default: [],
    },
    priority: {
      type: String,
      enum: {
        values: ['low', 'medium', 'high'],
        message: 'Priority must be low, medium, or high',
      },
      default: 'medium',
    },
    status: {
      type: String,
      enum: {
        values: ['pending', 'completed', 'cancelled'],
        message: 'Status must be pending, completed, or cancelled',
      },
      default: 'pending',
    },
    noteDate: {
      type: Date,
      default: () => {
        const now = new Date();
        now.setHours(0, 0, 0, 0);
        return now;
      },
    },
    reminderAt: {
      type: Date,
      default: null,
    },
    tags: {
      type: [String],
      default: [],
      validate: {
        validator: (v) => v.length <= 20,
        message: 'Cannot have more than 20 tags',
      },
    },
    totalAmount: {
      type: Number,
      default: 0,
      min: [0, 'Total amount cannot be negative'],
    },
    completedAt: {
      type: Date,
      default: null,
    },
    completedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Created by is required'],
    },
    modifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    // -- Soft delete fields --
    isDeleted: {
      type: Boolean,
      default: false,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
    deletedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    // -- Offline sync fields --
    isOfflineEntry: {
      type: Boolean,
      default: false,
    },
    offlineId: {
      type: String,
      default: null,
    },
    syncedAt: {
      type: Date,
      default: null,
    },

    // -- Future: ledger conversion tracking --
    convertedToLedger: {
      type: Boolean,
      default: false,
    },
    ledgerEntryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'LedgerEntry',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// ───────────────────────────────────────────────
// INDEXES
// ───────────────────────────────────────────────

// Primary query: list notes for a shop by date (most common query)
dailyNoteSchema.index({ shopId: 1, noteDate: -1, isDeleted: 1 });

// Filter by status within a shop
dailyNoteSchema.index({ shopId: 1, status: 1, noteDate: -1 });

// Filter by customer within a shop
dailyNoteSchema.index({ shopId: 1, customerId: 1, isDeleted: 1 });

// Filter by priority
dailyNoteSchema.index({ shopId: 1, priority: 1, status: 1 });

// Unique constraint: prevent duplicate title + date + customer per shop
dailyNoteSchema.index(
  { shopId: 1, title: 1, noteDate: 1, customerId: 1 },
  {
    unique: true,
    partialFilterExpression: { isDeleted: false },
    name: 'unique_note_per_day',
  }
);

// Text search on title + description
dailyNoteSchema.index(
  { title: 'text', description: 'text', tags: 'text' },
  { weights: { title: 10, tags: 5, description: 1 }, name: 'note_text_search' }
);

// Sync support: find changes since a timestamp
dailyNoteSchema.index({ shopId: 1, updatedAt: 1 });

// Offline sync dedup
dailyNoteSchema.index({ offlineId: 1 }, { sparse: true });

// Reminder scheduling
dailyNoteSchema.index(
  { shopId: 1, reminderAt: 1, status: 1 },
  { sparse: true, partialFilterExpression: { reminderAt: { $ne: null } } }
);

// ───────────────────────────────────────────────
// MIDDLEWARE
// ───────────────────────────────────────────────

// Auto-calculate totalAmount from structuredItems before save
dailyNoteSchema.pre('save', function (next) {
  if (this.structuredItems && this.structuredItems.length > 0) {
    this.totalAmount = +(
      this.structuredItems.reduce((sum, item) => {
        const itemTotal = +(item.quantity * item.unitPrice).toFixed(2);
        item.total = itemTotal;
        return sum + itemTotal;
      }, 0)
    ).toFixed(2);
  }
  next();
});

// ───────────────────────────────────────────────
// VIRTUALS
// ───────────────────────────────────────────────

// Whether the note has structured line-items
dailyNoteSchema.virtual('hasItems').get(function () {
  return this.structuredItems && this.structuredItems.length > 0;
});

// Whether reminder is overdue
dailyNoteSchema.virtual('isReminderOverdue').get(function () {
  if (!this.reminderAt) return false;
  return this.status === 'pending' && new Date() > this.reminderAt;
});

// Human-readable priority label
dailyNoteSchema.virtual('priorityLabel').get(function () {
  const labels = { low: 'Low', medium: 'Medium', high: 'High' };
  return labels[this.priority] || 'Medium';
});

dailyNoteSchema.set('toJSON', { virtuals: true });
dailyNoteSchema.set('toObject', { virtuals: true });

// ───────────────────────────────────────────────
// STATICS
// ───────────────────────────────────────────────

/**
 * Get today's notes for a shop
 */
dailyNoteSchema.statics.getTodayNotes = function (shopId) {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  return this.find({
    shopId,
    isDeleted: false,
    noteDate: { $gte: startOfDay, $lte: endOfDay },
  })
    .populate('customerId', 'name phone currentBalance')
    .populate('structuredItems.productId', 'name sellingPrice unit')
    .populate('createdBy', 'name')
    .sort({ priority: -1, createdAt: -1 })
    .lean();
};

/**
 * Get summary aggregation for a shop
 */
dailyNoteSchema.statics.getSummary = function (shopId, dateFrom, dateTo) {
  const match = {
    shopId: new mongoose.Types.ObjectId(shopId),
    isDeleted: false,
  };

  if (dateFrom || dateTo) {
    match.noteDate = {};
    if (dateFrom) match.noteDate.$gte = new Date(dateFrom);
    if (dateTo) match.noteDate.$lte = new Date(dateTo);
  }

  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        total: { $sum: 1 },
        pending: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
        completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
        cancelled: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } },
        highPriority: { $sum: { $cond: [{ $eq: ['$priority', 'high'] }, 1, 0] } },
        totalAmount: { $sum: '$totalAmount' },
        withCustomer: {
          $sum: { $cond: [{ $ne: ['$customerId', null] }, 1, 0] },
        },
      },
    },
  ]);
};

module.exports = mongoose.model('DailyNote', dailyNoteSchema);
