const mongoose = require('mongoose');

const ledgerEntrySchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      required: true,
    },
    type: {
      type: String,
      enum: ['credit', 'debit'],
      required: [true, 'Transaction type is required'],
      // credit = customer took items on udhar (shop gives, customer owes more)
      // debit = customer paid/returned (shop receives, customer owes less)
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0.01, 'Amount must be greater than 0'],
    },
    balanceAfter: {
      type: Number,
      required: true,
    },
    description: {
      type: String,
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },
    paymentMode: {
      type: String,
      enum: ['cash', 'upi', 'card', 'bank_transfer', 'cheque', 'other'],
      default: 'cash',
    },
    upiTransactionId: {
      type: String,
      trim: true,
    },
    attachments: [
      {
        url: String,
        type: {
          type: String,
          enum: ['image', 'document'],
        },
        uploadedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    linkedProducts: [
      {
        productId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Product',
        },
        quantity: Number,
        pricePerUnit: Number,
        totalPrice: Number,
      },
    ],
    isOfflineEntry: {
      type: Boolean,
      default: false,
    },
    offlineId: {
      type: String,
    },
    syncedAt: {
      type: Date,
      default: null,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    modifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
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
    },
    deletionReason: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for efficient querying
ledgerEntrySchema.index({ shopId: 1, customerId: 1, createdAt: -1 });
ledgerEntrySchema.index({ shopId: 1, createdAt: -1 });
ledgerEntrySchema.index({ customerId: 1, createdAt: -1 });
ledgerEntrySchema.index({ shopId: 1, type: 1, createdAt: -1 });
ledgerEntrySchema.index({ offlineId: 1 }, { sparse: true });
ledgerEntrySchema.index({ isDeleted: 1 });

// NOTE: Balance calculation (balanceAfter) and customer balance updates
// are handled atomically in the ledger controller using MongoDB sessions.
// This avoids the race condition of double-fetching the customer document
// and ensures consistency under concurrent requests.

module.exports = mongoose.model('LedgerEntry', ledgerEntrySchema);
