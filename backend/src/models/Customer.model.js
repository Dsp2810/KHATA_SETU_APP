const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    name: {
      type: String,
      required: [true, 'Customer name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [100, 'Name cannot exceed 100 characters'],
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
      match: [/^[6-9]\d{9}$/, 'Please enter a valid Indian phone number'],
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    address: {
      type: String,
      maxlength: [500, 'Address cannot exceed 500 characters'],
    },
    avatar: {
      type: String,
      default: null,
    },
    creditLimit: {
      type: Number,
      default: 0,
      min: [0, 'Credit limit cannot be negative'],
    },
    currentBalance: {
      type: Number,
      default: 0,
      // Positive = customer owes shop
      // Negative = shop owes customer
    },
    trustScore: {
      type: Number,
      default: 50,
      min: 0,
      max: 100,
    },
    tags: [String],
    notes: {
      type: String,
      maxlength: [1000, 'Notes cannot exceed 1000 characters'],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastTransactionAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for unique customer per shop by phone
customerSchema.index({ shopId: 1, phone: 1 }, { unique: true });
customerSchema.index({ shopId: 1, name: 'text' });
customerSchema.index({ shopId: 1, isActive: 1 });
customerSchema.index({ shopId: 1, currentBalance: 1 });
customerSchema.index({ lastTransactionAt: -1 });

// Virtual for balance status
customerSchema.virtual('balanceStatus').get(function () {
  if (this.currentBalance > 0) return 'owing'; // Customer owes
  if (this.currentBalance < 0) return 'owed'; // Shop owes
  return 'settled';
});

// Virtual for trust level
customerSchema.virtual('trustLevel').get(function () {
  if (this.trustScore >= 80) return 'high';
  if (this.trustScore >= 50) return 'medium';
  return 'low';
});

customerSchema.set('toJSON', { virtuals: true });
customerSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Customer', customerSchema);
