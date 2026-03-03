const mongoose = require('mongoose');

const syncQueueSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    deviceId: {
      type: String,
      required: true,
    },
    offlineId: {
      type: String,
      required: true,
    },
    operation: {
      type: String,
      enum: ['create', 'update', 'delete'],
      required: true,
    },
    entityType: {
      type: String,
      enum: ['customer', 'ledger_entry', 'product', 'inventory_transaction', 'reminder'],
      required: true,
    },
    entityId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },
    payload: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    clientTimestamp: {
      type: Date,
      required: true,
    },
    priority: {
      type: Number,
      default: 0,
      // Higher number = higher priority
      // Ledger entries should have highest priority
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed', 'conflict'],
      default: 'pending',
    },
    processedAt: {
      type: Date,
      default: null,
    },
    errorMessage: {
      type: String,
      default: null,
    },
    retryCount: {
      type: Number,
      default: 0,
    },
    maxRetries: {
      type: Number,
      default: 3,
    },
    conflictData: {
      serverVersion: mongoose.Schema.Types.Mixed,
      resolution: {
        type: String,
        enum: ['client_wins', 'server_wins', 'manual', 'merged'],
      },
      resolvedAt: Date,
      resolvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    },
    syncBatchId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
syncQueueSchema.index({ userId: 1, status: 1, createdAt: 1 });
syncQueueSchema.index({ shopId: 1, status: 1 });
syncQueueSchema.index({ offlineId: 1 }, { unique: true });
syncQueueSchema.index({ deviceId: 1, status: 1 });
syncQueueSchema.index({ status: 1, priority: -1, createdAt: 1 });
syncQueueSchema.index({ syncBatchId: 1 });

// Static method to add to queue
syncQueueSchema.statics.addToQueue = async function (data) {
  const priority = {
    ledger_entry: 100,
    inventory_transaction: 90,
    customer: 80,
    product: 70,
    reminder: 60,
  };
  
  return this.create({
    ...data,
    priority: priority[data.entityType] || 0,
  });
};

// Static method to get pending items for processing
syncQueueSchema.statics.getPendingItems = function (shopId, limit = 50) {
  return this.find({
    shopId,
    status: { $in: ['pending', 'failed'] },
    retryCount: { $lt: 3 },
  })
    .sort({ priority: -1, createdAt: 1 })
    .limit(limit);
};

// Static method to mark as completed
syncQueueSchema.statics.markCompleted = async function (offlineId, entityId) {
  return this.findOneAndUpdate(
    { offlineId },
    {
      status: 'completed',
      entityId,
      processedAt: new Date(),
    }
  );
};

// Static method to mark as failed
syncQueueSchema.statics.markFailed = async function (offlineId, errorMessage) {
  return this.findOneAndUpdate(
    { offlineId },
    {
      status: 'failed',
      errorMessage,
      $inc: { retryCount: 1 },
    }
  );
};

// Static method to mark as conflict
syncQueueSchema.statics.markConflict = async function (offlineId, serverVersion) {
  return this.findOneAndUpdate(
    { offlineId },
    {
      status: 'conflict',
      'conflictData.serverVersion': serverVersion,
    }
  );
};

// Static method to resolve conflict
syncQueueSchema.statics.resolveConflict = async function (offlineId, resolution, resolvedBy) {
  return this.findOneAndUpdate(
    { offlineId },
    {
      status: 'completed',
      'conflictData.resolution': resolution,
      'conflictData.resolvedAt': new Date(),
      'conflictData.resolvedBy': resolvedBy,
      processedAt: new Date(),
    }
  );
};

// Static method to get sync status summary
syncQueueSchema.statics.getSyncStatus = async function (shopId) {
  const result = await this.aggregate([
    { $match: { shopId: new mongoose.Types.ObjectId(shopId) } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
      },
    },
  ]);
  
  return result.reduce((acc, item) => {
    acc[item._id] = item.count;
    return acc;
  }, {});
};

// Static method to cleanup old completed items
syncQueueSchema.statics.cleanup = async function (daysOld = 7) {
  const cutoff = new Date(Date.now() - daysOld * 24 * 60 * 60 * 1000);
  return this.deleteMany({
    status: 'completed',
    processedAt: { $lt: cutoff },
  });
};

module.exports = mongoose.model('SyncQueue', syncQueueSchema);
