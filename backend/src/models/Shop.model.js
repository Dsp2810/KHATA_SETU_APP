const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    name: {
      type: String,
      required: [true, 'Shop name is required'],
      trim: true,
      minlength: [2, 'Shop name must be at least 2 characters'],
      maxlength: [150, 'Shop name cannot exceed 150 characters'],
    },
    type: {
      type: String,
      enum: ['kirana', 'grocery', 'general_store', 'medical', 'hardware', 'electronics', 'other'],
      default: 'general_store',
    },
    address: {
      street: String,
      village: String,
      city: String,
      district: String,
      state: { type: String, default: 'Gujarat' },
      pincode: String,
    },
    phone: {
      type: String,
      match: [/^[6-9]\d{9}$/, 'Please enter a valid phone number'],
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    logo: {
      type: String,
      default: null,
    },
    gstNumber: {
      type: String,
      trim: true,
    },
    settings: {
      currency: { type: String, default: 'INR' },
      defaultCreditLimit: { type: Number, default: 0 },
      reminderDays: { type: Number, default: 7 },
      autoReminder: { type: Boolean, default: true },
    },
    employees: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        name: String,
        phone: String,
        role: {
          type: String,
          enum: ['manager', 'cashier', 'staff'],
          default: 'staff',
        },
        permissions: [{
          type: String,
          enum: [
            'view_customers', 'manage_customers',
            'view_ledger', 'manage_ledger',
            'view_inventory', 'manage_inventory',
            'view_reports', 'manage_shop',
            'manage_employees', 'manage_reminders',
          ],
        }],
        isActive: { type: Boolean, default: true },
        addedAt: { type: Date, default: Date.now },
      },
    ],
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
shopSchema.index({ owner: 1 });
shopSchema.index({ isActive: 1 });
shopSchema.index({ 'employees.userId': 1 });

module.exports = mongoose.model('Shop', shopSchema);
