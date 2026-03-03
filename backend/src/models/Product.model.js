const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    name: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
      maxlength: [200, 'Product name cannot exceed 200 characters'],
    },
    localName: {
      type: String,
      trim: true,
      maxlength: [200, 'Local name cannot exceed 200 characters'],
    },
    description: {
      type: String,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },
    category: {
      type: String,
      trim: true,
      maxlength: [100, 'Category cannot exceed 100 characters'],
    },
    subCategory: {
      type: String,
      trim: true,
    },
    sku: {
      type: String,
      trim: true,
    },
    barcode: {
      type: String,
      trim: true,
    },
    unit: {
      type: String,
      enum: ['piece', 'kg', 'gram', 'liter', 'ml', 'meter', 'dozen', 'packet', 'box', 'bundle', 'other'],
      default: 'piece',
    },
    purchasePrice: {
      type: Number,
      required: [true, 'Purchase price is required'],
      min: [0, 'Purchase price cannot be negative'],
    },
    sellingPrice: {
      type: Number,
      required: [true, 'Selling price is required'],
      min: [0, 'Selling price cannot be negative'],
    },
    mrp: {
      type: Number,
      min: [0, 'MRP cannot be negative'],
    },
    taxRate: {
      type: Number,
      default: 0,
      min: [0, 'Tax rate cannot be negative'],
      max: [100, 'Tax rate cannot exceed 100%'],
    },
    currentStock: {
      type: Number,
      default: 0,
      min: [0, 'Stock cannot be negative'],
    },
    minStockLevel: {
      type: Number,
      default: 5,
      min: [0, 'Minimum stock level cannot be negative'],
    },
    maxStockLevel: {
      type: Number,
      default: 1000,
    },
    reorderPoint: {
      type: Number,
      default: 10,
    },
    images: [
      {
        url: String,
        isPrimary: {
          type: Boolean,
          default: false,
        },
        uploadedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    supplier: {
      name: String,
      phone: String,
      address: String,
    },
    expiryDate: {
      type: Date,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    tags: [String],
    lastRestockedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
productSchema.index({ shopId: 1, name: 'text', localName: 'text' });
productSchema.index({ shopId: 1, category: 1 });
productSchema.index({ shopId: 1, isActive: 1 });
productSchema.index({ shopId: 1, barcode: 1 }, { sparse: true });
productSchema.index({ shopId: 1, sku: 1 }, { sparse: true });
productSchema.index({ shopId: 1, currentStock: 1, minStockLevel: 1 });

// Virtual for profit margin
productSchema.virtual('profitMargin').get(function () {
  if (this.purchasePrice === 0) return 100;
  return (((this.sellingPrice - this.purchasePrice) / this.purchasePrice) * 100).toFixed(2);
});

// Virtual for low stock status
productSchema.virtual('isLowStock').get(function () {
  return this.currentStock <= this.minStockLevel;
});

// Virtual for out of stock status
productSchema.virtual('isOutOfStock').get(function () {
  return this.currentStock === 0;
});

// Virtual for stock value
productSchema.virtual('stockValue').get(function () {
  return this.currentStock * this.purchasePrice;
});

productSchema.set('toJSON', { virtuals: true });
productSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Product', productSchema);
