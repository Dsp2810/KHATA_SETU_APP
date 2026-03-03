const mongoose = require('mongoose');

const refreshTokenSchema = new mongoose.Schema(
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
    deviceInfo: {
      deviceId: String,
      deviceType: {
        type: String,
        enum: ['android', 'ios', 'web'],
      },
      deviceName: String,
      osVersion: String,
      appVersion: String,
    },
    ipAddress: {
      type: String,
    },
    userAgent: {
      type: String,
    },
    isRevoked: {
      type: Boolean,
      default: false,
    },
    revokedAt: {
      type: Date,
      default: null,
    },
    revokedReason: {
      type: String,
      enum: ['logout', 'security', 'expired', 'replaced', 'admin'],
    },
    expiresAt: {
      type: Date,
      required: true,
    },
    lastUsedAt: {
      type: Date,
      default: Date.now,
    },
    rotationCount: {
      type: Number,
      default: 0,
    },
    previousTokenId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RefreshToken',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
refreshTokenSchema.index({ token: 1 }, { unique: true });
refreshTokenSchema.index({ userId: 1, isRevoked: 1 });
refreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index
refreshTokenSchema.index({ 'deviceInfo.deviceId': 1, userId: 1 });

// Static method to revoke all tokens for a user
refreshTokenSchema.statics.revokeAllForUser = async function (userId, reason = 'security') {
  return this.updateMany(
    { userId, isRevoked: false },
    {
      isRevoked: true,
      revokedAt: new Date(),
      revokedReason: reason,
    }
  );
};

// Static method to revoke token by device
refreshTokenSchema.statics.revokeByDevice = async function (userId, deviceId, reason = 'logout') {
  return this.updateMany(
    { userId, 'deviceInfo.deviceId': deviceId, isRevoked: false },
    {
      isRevoked: true,
      revokedAt: new Date(),
      revokedReason: reason,
    }
  );
};

// Static method to clean up expired tokens
refreshTokenSchema.statics.cleanupExpired = async function () {
  return this.deleteMany({
    $or: [
      { expiresAt: { $lt: new Date() } },
      { isRevoked: true, revokedAt: { $lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
    ],
  });
};

// Instance method to revoke
refreshTokenSchema.methods.revoke = async function (reason = 'logout') {
  this.isRevoked = true;
  this.revokedAt = new Date();
  this.revokedReason = reason;
  return this.save();
};

// Instance method to update last used
refreshTokenSchema.methods.updateLastUsed = async function () {
  this.lastUsedAt = new Date();
  return this.save();
};

module.exports = mongoose.model('RefreshToken', refreshTokenSchema);
