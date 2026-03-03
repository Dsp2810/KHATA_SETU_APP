const mongoose = require('mongoose');

const fcmTokenSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    token: {
      type: String,
      required: true,
    },
    deviceId: {
      type: String,
      required: true,
    },
    deviceType: {
      type: String,
      enum: ['android', 'ios', 'web'],
      required: true,
    },
    deviceName: {
      type: String,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastUsedAt: {
      type: Date,
      default: Date.now,
    },
    failureCount: {
      type: Number,
      default: 0,
    },
    lastFailureAt: {
      type: Date,
      default: null,
    },
    lastFailureReason: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index
fcmTokenSchema.index({ userId: 1, deviceId: 1 }, { unique: true });
fcmTokenSchema.index({ token: 1 });
fcmTokenSchema.index({ userId: 1, isActive: 1 });

// Static method to register or update token
fcmTokenSchema.statics.registerToken = async function (userId, tokenData) {
  const { token, deviceId, deviceType, deviceName } = tokenData;
  
  return this.findOneAndUpdate(
    { userId, deviceId },
    {
      token,
      deviceType,
      deviceName,
      isActive: true,
      lastUsedAt: new Date(),
      failureCount: 0,
      lastFailureAt: null,
      lastFailureReason: null,
    },
    { upsert: true, new: true }
  );
};

// Static method to get active tokens for user
fcmTokenSchema.statics.getActiveTokens = function (userId) {
  return this.find({ userId, isActive: true }).select('token deviceType');
};

// Static method to mark token as failed
fcmTokenSchema.statics.markFailed = async function (token, reason) {
  const doc = await this.findOne({ token });
  if (doc) {
    doc.failureCount += 1;
    doc.lastFailureAt = new Date();
    doc.lastFailureReason = reason;
    
    // Deactivate after 3 consecutive failures
    if (doc.failureCount >= 3) {
      doc.isActive = false;
    }
    
    await doc.save();
  }
};

// Static method to deactivate token
fcmTokenSchema.statics.deactivate = async function (userId, deviceId) {
  return this.findOneAndUpdate(
    { userId, deviceId },
    { isActive: false }
  );
};

// Static method to deactivate all tokens for user
fcmTokenSchema.statics.deactivateAll = async function (userId) {
  return this.updateMany(
    { userId },
    { isActive: false }
  );
};

module.exports = mongoose.model('FCMToken', fcmTokenSchema);
