const bcrypt = require('bcryptjs');
const crypto = require('crypto');

/**
 * Hash a password
 * @param {string} password - Plain text password
 * @param {number} saltRounds - Number of salt rounds (default: 12)
 * @returns {Promise<string>} Hashed password
 */
const hashPassword = async (password, saltRounds = 12) => {
  const salt = await bcrypt.genSalt(saltRounds);
  return bcrypt.hash(password, salt);
};

/**
 * Compare password with hash
 * @param {string} password - Plain text password
 * @param {string} hash - Hashed password
 * @returns {Promise<boolean>} Whether password matches
 */
const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

/**
 * Generate a secure random password
 * @param {number} length - Password length (default: 16)
 * @returns {string} Random password
 */
const generateRandomPassword = (length = 16) => {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '!@#$%^&*';
  
  const allChars = uppercase + lowercase + numbers + special;
  
  // Ensure at least one of each type
  let password = '';
  password += uppercase[Math.floor(Math.random() * uppercase.length)];
  password += lowercase[Math.floor(Math.random() * lowercase.length)];
  password += numbers[Math.floor(Math.random() * numbers.length)];
  password += special[Math.floor(Math.random() * special.length)];
  
  // Fill the rest randomly
  for (let i = password.length; i < length; i++) {
    password += allChars[Math.floor(Math.random() * allChars.length)];
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
};

/**
 * Generate PIN
 * @param {number} length - PIN length (default: 4)
 * @returns {string} Random PIN
 */
const generatePIN = (length = 4) => {
  let pin = '';
  for (let i = 0; i < length; i++) {
    pin += Math.floor(Math.random() * 10);
  }
  return pin;
};

/**
 * Hash PIN (lighter than bcrypt for PINs)
 * @param {string} pin - Plain PIN
 * @returns {string} Hashed PIN
 */
const hashPIN = (pin) => {
  return crypto.createHash('sha256').update(pin).digest('hex');
};

/**
 * Verify PIN
 * @param {string} plainPin - Plain PIN
 * @param {string} hashedPin - Hashed PIN
 * @returns {boolean} Whether PIN matches
 */
const verifyPIN = (plainPin, hashedPin) => {
  const hashed = hashPIN(plainPin);
  return crypto.timingSafeEqual(Buffer.from(hashed), Buffer.from(hashedPin));
};

/**
 * Hash sensitive data (for logging purposes)
 * @param {string} data - Data to hash
 * @returns {string} Masked/hashed data
 */
const maskSensitiveData = (data) => {
  if (!data) return '';
  
  if (data.length <= 4) {
    return '*'.repeat(data.length);
  }
  
  const visible = Math.min(4, Math.floor(data.length / 4));
  return data.substring(0, visible) + '*'.repeat(data.length - visible * 2) + data.substring(data.length - visible);
};

/**
 * Mask phone number for display
 * @param {string} phone - Phone number
 * @returns {string} Masked phone
 */
const maskPhone = (phone) => {
  if (!phone || phone.length < 10) return phone;
  return phone.substring(0, 2) + '****' + phone.substring(phone.length - 4);
};

/**
 * Mask email for display
 * @param {string} email - Email address
 * @returns {string} Masked email
 */
const maskEmail = (email) => {
  if (!email) return email;
  
  const [localPart, domain] = email.split('@');
  if (!localPart || !domain) return email;
  
  const maskedLocal = localPart.substring(0, 2) + '***';
  return `${maskedLocal}@${domain}`;
};

module.exports = {
  hashPassword,
  comparePassword,
  generateRandomPassword,
  generatePIN,
  hashPIN,
  verifyPIN,
  maskSensitiveData,
  maskPhone,
  maskEmail,
};
