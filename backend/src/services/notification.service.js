let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  // firebase-admin not available
}
const { FCMToken } = require('../models');
const { logger } = require('../utils');
const config = require('../config/config');

// Initialize Firebase Admin (only if credentials are configured)
let firebaseApp = null;
try {
  if (admin && config.firebase.serviceAccount && config.firebase.serviceAccount.trim()) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(config.firebase.serviceAccount)),
    });
    logger.info('Firebase initialized successfully');
  } else {
    logger.info('Firebase not configured - push notifications disabled (OK for testing)');
  }
} catch (error) {
  logger.warn('Firebase initialization skipped:', error.message);
}

/**
 * Send push notification to a user
 * @param {string} userId - User ID
 * @param {object} notification - Notification payload
 * @param {object} data - Additional data payload
 */
const sendToUser = async (userId, notification, data = {}) => {
  if (!firebaseApp) {
    logger.warn('Firebase not initialized, skipping push notification');
    return { success: false, reason: 'firebase_not_initialized' };
  }
  
  try {
    const tokens = await FCMToken.getActiveTokens(userId);
    
    if (tokens.length === 0) {
      return { success: false, reason: 'no_tokens' };
    }
    
    const results = await Promise.all(
      tokens.map(async (tokenDoc) => {
        try {
          const message = {
            token: tokenDoc.token,
            notification: {
              title: notification.title,
              body: notification.body,
            },
            data: {
              ...data,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: {
                channelId: data.channelId || 'default',
                sound: 'default',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          };
          
          await admin.messaging().send(message);
          await tokenDoc.updateLastUsed();
          
          return { success: true, deviceId: tokenDoc.deviceId };
        } catch (error) {
          // Handle invalid token
          if (
            error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered'
          ) {
            await FCMToken.markFailed(tokenDoc.token, error.message);
          }
          
          return { success: false, deviceId: tokenDoc.deviceId, error: error.message };
        }
      })
    );
    
    const successful = results.filter((r) => r.success).length;
    
    logger.info('Push notification sent', {
      userId,
      totalTokens: tokens.length,
      successful,
    });
    
    return {
      success: successful > 0,
      sent: successful,
      total: tokens.length,
      results,
    };
  } catch (error) {
    logger.error('Error sending push notification:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send notification to multiple users
 * @param {string[]} userIds - Array of user IDs
 * @param {object} notification - Notification payload
 * @param {object} data - Additional data payload
 */
const sendToUsers = async (userIds, notification, data = {}) => {
  const results = await Promise.all(
    userIds.map((userId) => sendToUser(userId, notification, data))
  );
  
  return {
    total: userIds.length,
    successful: results.filter((r) => r.success).length,
    results,
  };
};

/**
 * Send reminder notification
 * @param {object} reminder - Reminder document
 */
const sendReminderNotification = async (reminder) => {
  const notification = {
    title: reminder.title,
    body: reminder.message || `Payment reminder for ${reminder.customerId?.name || 'Customer'}`,
  };
  
  const data = {
    type: 'reminder',
    reminderId: reminder._id.toString(),
    customerId: reminder.customerId?._id?.toString() || '',
    amount: reminder.amount?.toString() || '0',
    channelId: 'reminders',
  };
  
  // Get shop owner to send notification to
  const { Shop } = require('../models');
  const shop = await Shop.findById(reminder.shopId);
  
  if (shop) {
    await sendToUser(shop.owner.toString(), notification, data);
  }
};

/**
 * Send transaction notification
 * @param {object} entry - Ledger entry
 * @param {object} customer - Customer
 */
const sendTransactionNotification = async (entry, customer) => {
  const type = entry.type === 'credit' ? 'Credit' : 'Payment';
  
  const notification = {
    title: `${type} Recorded`,
    body: `₹${entry.amount} ${type.toLowerCase()} for ${customer.name}. New balance: ₹${customer.currentBalance}`,
  };
  
  const data = {
    type: 'transaction',
    entryId: entry._id.toString(),
    customerId: customer._id.toString(),
    channelId: 'transactions',
  };
  
  // Send to shop owner
  const { Shop } = require('../models');
  const shop = await Shop.findById(entry.shopId);
  
  if (shop) {
    await sendToUser(shop.owner.toString(), notification, data);
  }
};

/**
 * Send low stock alert
 * @param {object} product - Product with low stock
 * @param {string} shopId - Shop ID
 */
const sendLowStockAlert = async (product, shopId) => {
  const notification = {
    title: 'Low Stock Alert',
    body: `${product.name} is running low. Current stock: ${product.currentStock}`,
  };
  
  const data = {
    type: 'low_stock',
    productId: product._id.toString(),
    channelId: 'inventory',
  };
  
  const { Shop } = require('../models');
  const shop = await Shop.findById(shopId);
  
  if (shop) {
    await sendToUser(shop.owner.toString(), notification, data);
  }
};

module.exports = {
  sendToUser,
  sendToUsers,
  sendReminderNotification,
  sendTransactionNotification,
  sendLowStockAlert,
};
