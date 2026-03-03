const mongoose = require('mongoose');

const inventoryTransactionSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
    },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
    },
    type: {
      type: String,
      enum: ['stock_in', 'stock_out', 'sale', 'return', 'adjustment', 'damage', 'expired'],
      required: [true, 'Transaction type is required'],
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: [0.01, 'Quantity must be greater than 0'],
    },
    previousStock: {
      type: Number,
      required: true,
    },
    newStock: {
      type: Number,
      required: true,
    },
    unitPrice: {
      type: Number,
      required: true,
      min: [0, 'Unit price cannot be negative'],
    },
    totalValue: {
      type: Number,
      required: true,
    },
    referenceType: {
      type: String,
      enum: ['purchase', 'sale', 'ledger_entry', 'manual', 'return'],
      default: 'manual',
    },
    referenceId: {
      type: mongoose.Schema.Types.ObjectId,
      refPath: 'referenceModel',
    },
    referenceModel: {
      type: String,
      enum: ['LedgerEntry', 'Purchase', 'Return'],
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      default: null,
    },
    supplierName: {
      type: String,
      trim: true,
    },
    batchNumber: {
      type: String,
      trim: true,
    },
    expiryDate: {
      type: Date,
      default: null,
    },
    notes: {
      type: String,
      maxlength: [500, 'Notes cannot exceed 500 characters'],
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
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
  },
  {
    timestamps: true,
  }
);

// Indexes
inventoryTransactionSchema.index({ shopId: 1, productId: 1, createdAt: -1 });
inventoryTransactionSchema.index({ shopId: 1, type: 1, createdAt: -1 });
inventoryTransactionSchema.index({ shopId: 1, createdAt: -1 });
inventoryTransactionSchema.index({ productId: 1, createdAt: -1 });
inventoryTransactionSchema.index({ offlineId: 1 }, { sparse: true });

// Pre-save middleware to update product stock
inventoryTransactionSchema.pre('save', async function (next) {
  if (this.isNew) {
    const Product = mongoose.model('Product');
    const product = await Product.findById(this.productId);
    
    if (!product) {
      return next(new Error('Product not found'));
    }
    
    this.previousStock = product.currentStock;
    
    // Update stock based on transaction type
    switch (this.type) {
      case 'stock_in':
      case 'return':
        product.currentStock += this.quantity;
        break;
      case 'stock_out':
      case 'sale':
      case 'damage':
      case 'expired':
        if (product.currentStock < this.quantity) {
          return next(new Error('Insufficient stock'));
        }
        product.currentStock -= this.quantity;
        break;
      case 'adjustment':
        // For adjustment, quantity can be positive (add) or negative (subtract)
        product.currentStock = this.quantity;
        break;
    }
    
    this.newStock = product.currentStock;
    this.totalValue = this.quantity * this.unitPrice;
    
    if (this.type === 'stock_in') {
      product.lastRestockedAt = new Date();
    }
    
    await product.save();
  }
  next();
});

module.exports = mongoose.model('InventoryTransaction', inventoryTransactionSchema);
