const { logger } = require('../utils');
const config = require('../config/config');

// SMS Provider configurations
const providers = {
  MSG91: 'msg91',
  TWILIO: 'twilio',
  TEXTLOCAL: 'textlocal',
  MOCK: 'mock', // For development/testing
};

// Current provider (from config)
const currentProvider = config.sms?.provider || providers.MOCK;

// OTP Templates
const templates = {
  OTP: (otp, expiry = 5) => 
    `Your KhataSetu verification code is ${otp}. Valid for ${expiry} minutes. Do not share this with anyone.`,
  
  PAYMENT_REMINDER: (shopName, amount, customerName) =>
    `Reminder from ${shopName}: Payment of ₹${amount} is due. - ${customerName}`,
  
  TRANSACTION: (shopName, type, amount, balance) =>
    `${shopName}: ${type === 'credit' ? 'Credit' : 'Payment'} of ₹${amount} recorded. Balance: ₹${balance}`,
};

/**
 * Send SMS via MSG91
 */
const sendViaMSG91 = async (phone, message) => {
  try {
    const axios = require('axios');
    const response = await axios.get('https://api.msg91.com/api/sendhttp.php', {
      params: {
        authkey: config.sms.msg91AuthKey,
        mobiles: phone.replace('+', ''),
        message: message,
        sender: config.sms.senderId || 'KHATAS',
        route: '4', // Transactional route
        country: '91',
      },
    });
    
    return {
      success: true,
      provider: providers.MSG91,
      messageId: response.data,
    };
  } catch (error) {
    logger.error('MSG91 SMS error:', error);
    throw error;
  }
};

/**
 * Send SMS via Twilio
 */
const sendViaTwilio = async (phone, message) => {
  try {
    const client = require('twilio')(
      config.sms.twilioAccountSid,
      config.sms.twilioAuthToken
    );
    
    const result = await client.messages.create({
      body: message,
      from: config.sms.twilioPhoneNumber,
      to: phone,
    });
    
    return {
      success: true,
      provider: providers.TWILIO,
      messageId: result.sid,
    };
  } catch (error) {
    logger.error('Twilio SMS error:', error);
    throw error;
  }
};

/**
 * Send SMS via TextLocal
 */
const sendViaTextLocal = async (phone, message) => {
  try {
    const axios = require('axios');
    const response = await axios.post('https://api.textlocal.in/send/', null, {
      params: {
        apikey: config.sms.textLocalApiKey,
        numbers: phone.replace('+91', ''),
        message: message,
        sender: config.sms.senderId || 'KHATAS',
      },
    });
    
    if (response.data.status !== 'success') {
      throw new Error(response.data.errors?.[0]?.message || 'TextLocal error');
    }
    
    return {
      success: true,
      provider: providers.TEXTLOCAL,
      messageId: response.data.messages?.[0]?.id,
    };
  } catch (error) {
    logger.error('TextLocal SMS error:', error);
    throw error;
  }
};

/**
 * Mock SMS sender for development
 */
const sendViaMock = async (phone, message) => {
  logger.info('Mock SMS sent:', { phone, message });
  
  // Simulate network delay
  await new Promise((resolve) => setTimeout(resolve, 100));
  
  return {
    success: true,
    provider: providers.MOCK,
    messageId: `mock_${Date.now()}`,
  };
};

/**
 * Send SMS using configured provider
 * @param {string} phone - Phone number with country code
 * @param {string} message - SMS message
 * @returns {Promise<object>} - Result object
 */
const sendSMS = async (phone, message) => {
  // Validate phone number format
  if (!phone || !/^\+?[1-9]\d{9,14}$/.test(phone.replace(/\s/g, ''))) {
    throw new Error('Invalid phone number format');
  }
  
  // Ensure country code
  let formattedPhone = phone.replace(/\s/g, '');
  if (!formattedPhone.startsWith('+')) {
    formattedPhone = '+91' + formattedPhone; // Default to India
  }
  
  logger.info('Sending SMS', { provider: currentProvider, phone: formattedPhone });
  
  try {
    let result;
    
    switch (currentProvider) {
      case providers.MSG91:
        result = await sendViaMSG91(formattedPhone, message);
        break;
      case providers.TWILIO:
        result = await sendViaTwilio(formattedPhone, message);
        break;
      case providers.TEXTLOCAL:
        result = await sendViaTextLocal(formattedPhone, message);
        break;
      case providers.MOCK:
      default:
        result = await sendViaMock(formattedPhone, message);
        break;
    }
    
    logger.info('SMS sent successfully', { phone: formattedPhone, ...result });
    return result;
  } catch (error) {
    logger.error('SMS sending failed', { phone: formattedPhone, error: error.message });
    throw error;
  }
};

/**
 * Send OTP via SMS
 * @param {string} phone - Phone number
 * @param {string} purpose - OTP purpose (login, register, reset)
 * @returns {Promise<object>} - OTP details with hash
 */
const sendOTP = async (phone, purpose = 'verification') => {
  // Generate OTP
  const otp = tokenUtil.generateOTP(6);
  const otpHash = tokenUtil.hashOTP(otp);
  const expiry = 5; // minutes
  
  // Create message
  const message = templates.OTP(otp, expiry);
  
  // Send SMS
  const result = await sendSMS(phone, message);
  
  return {
    ...result,
    otpHash,
    expiresIn: expiry * 60, // seconds
    purpose,
    // Include OTP only in development for testing
    ...(process.env.NODE_ENV === 'development' && { otp }),
  };
};

/**
 * Send payment reminder SMS
 * @param {object} reminder - Reminder details
 * @param {object} customer - Customer details
 * @param {object} shop - Shop details
 */
const sendPaymentReminderSMS = async (reminder, customer, shop) => {
  if (!customer.phone) {
    throw new Error('Customer phone number not available');
  }
  
  const message = templates.PAYMENT_REMINDER(
    shop.name,
    reminder.amount || customer.currentBalance,
    customer.name
  );
  
  return await sendSMS(customer.phone, message);
};

/**
 * Send transaction notification SMS
 * @param {object} entry - Ledger entry
 * @param {object} customer - Customer
 * @param {object} shop - Shop
 */
const sendTransactionSMS = async (entry, customer, shop) => {
  if (!customer.phone) {
    return { success: false, reason: 'no_phone' };
  }
  
  const message = templates.TRANSACTION(
    shop.name,
    entry.type,
    entry.amount,
    customer.currentBalance
  );
  
  return await sendSMS(customer.phone, message);
};

/**
 * Send WhatsApp message (via Twilio or WhatsApp Business API)
 * @param {string} phone - Phone number
 * @param {string} message - Message content
 */
const sendWhatsApp = async (phone, message) => {
  if (!config.sms.twilioAccountSid || !config.sms.whatsappNumber) {
    logger.warn('WhatsApp not configured');
    return { success: false, reason: 'not_configured' };
  }
  
  try {
    const client = require('twilio')(
      config.sms.twilioAccountSid,
      config.sms.twilioAuthToken
    );
    
    let formattedPhone = phone.replace(/\s/g, '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91' + formattedPhone;
    }
    
    const result = await client.messages.create({
      body: message,
      from: `whatsapp:${config.sms.whatsappNumber}`,
      to: `whatsapp:${formattedPhone}`,
    });
    
    return {
      success: true,
      provider: 'whatsapp',
      messageId: result.sid,
    };
  } catch (error) {
    logger.error('WhatsApp error:', error);
    throw error;
  }
};

module.exports = {
  sendSMS,
  sendOTP,
  sendPaymentReminderSMS,
  sendTransactionSMS,
  sendWhatsApp,
  templates,
  providers,
};
