const { Reminder, Customer } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');
const mongoose = require('mongoose');

/**
 * Create a new reminder
 * POST /api/shops/:shopId/reminders
 */
const createReminder = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  // Verify customer exists
  const customer = await Customer.findOne({
    _id: req.body.customerId,
    shopId,
  });
  
  if (!customer) {
    throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
  }
  
  const reminderData = {
    ...req.body,
    shopId,
    createdBy: req.userId,
  };
  
  const reminder = await Reminder.create(reminderData);
  
  await reminder.populate('customerId', 'name phone currentBalance');
  
  auditLog('REMINDER_CREATED', req.userId, {
    reminderId: reminder._id,
    shopId,
    customerId: req.body.customerId,
  });
  
  res.status(201).json({
    success: true,
    message: 'Reminder created successfully',
    data: { reminder },
  });
});

/**
 * Get all reminders for a shop
 * GET /api/shops/:shopId/reminders
 */
const getReminders = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const {
    customerId,
    type,
    status,
    priority,
    startDate,
    endDate,
    isOverdue,
    sortBy,
    sortOrder,
    page,
    limit,
  } = req.query;
  
  // Build query
  const query = {
    shopId: new mongoose.Types.ObjectId(shopId),
    isDeleted: false,
  };
  
  if (customerId) {
    query.customerId = new mongoose.Types.ObjectId(customerId);
  }
  
  if (type) {
    query.type = type;
  }
  
  if (status) {
    query.status = status;
  }
  
  if (priority) {
    query.priority = priority;
  }
  
  if (startDate) {
    query.scheduledAt = { $gte: new Date(startDate) };
  }
  
  if (endDate) {
    query.scheduledAt = { ...query.scheduledAt, $lte: new Date(endDate) };
  }
  
  if (isOverdue) {
    query.status = 'pending';
    query.scheduledAt = { $lt: new Date() };
  }
  
  // Build sort
  const sort = {};
  sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
  
  // Pagination
  const skip = (page - 1) * limit;
  
  // Execute query
  const [reminders, totalCount] = await Promise.all([
    Reminder.find(query)
      .populate('customerId', 'name phone currentBalance')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Reminder.countDocuments(query),
  ]);
  
  // Get summary
  const now = new Date();
  const summary = await Reminder.aggregate([
    { $match: { shopId: new mongoose.Types.ObjectId(shopId), isDeleted: false } },
    {
      $group: {
        _id: null,
        total: { $sum: 1 },
        pending: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
        overdue: {
          $sum: {
            $cond: [
              {
                $and: [
                  { $eq: ['$status', 'pending'] },
                  { $lt: ['$scheduledAt', now] },
                ],
              },
              1,
              0,
            ],
          },
        },
        todayCount: {
          $sum: {
            $cond: [
              {
                $and: [
                  { $eq: ['$status', 'pending'] },
                  { $gte: ['$scheduledAt', new Date(now.toDateString())] },
                  { $lt: ['$scheduledAt', new Date(now.getTime() + 24 * 60 * 60 * 1000)] },
                ],
              },
              1,
              0,
            ],
          },
        },
      },
    },
  ]);
  
  res.json({
    success: true,
    data: {
      reminders,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
      summary: summary[0] || {
        total: 0,
        pending: 0,
        overdue: 0,
        todayCount: 0,
      },
    },
  });
});

/**
 * Get a single reminder
 * GET /api/shops/:shopId/reminders/:reminderId
 */
const getReminder = asyncHandler(async (req, res) => {
  const { shopId, reminderId } = req.params;
  
  const reminder = await Reminder.findOne({
    _id: reminderId,
    shopId,
    isDeleted: false,
  }).populate('customerId', 'name phone currentBalance');
  
  if (!reminder) {
    throw new AppError('Reminder not found', 404, 'REMINDER_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { reminder },
  });
});

/**
 * Update a reminder
 * PATCH /api/shops/:shopId/reminders/:reminderId
 */
const updateReminder = asyncHandler(async (req, res) => {
  const { shopId, reminderId } = req.params;
  
  const reminder = await Reminder.findOneAndUpdate(
    { _id: reminderId, shopId, isDeleted: false },
    req.body,
    { new: true, runValidators: true }
  ).populate('customerId', 'name phone');
  
  if (!reminder) {
    throw new AppError('Reminder not found', 404, 'REMINDER_NOT_FOUND');
  }
  
  auditLog('REMINDER_UPDATED', req.userId, {
    reminderId,
    shopId,
    updates: Object.keys(req.body),
  });
  
  res.json({
    success: true,
    message: 'Reminder updated successfully',
    data: { reminder },
  });
});

/**
 * Delete a reminder
 * DELETE /api/shops/:shopId/reminders/:reminderId
 */
const deleteReminder = asyncHandler(async (req, res) => {
  const { shopId, reminderId } = req.params;
  
  const reminder = await Reminder.findOneAndUpdate(
    { _id: reminderId, shopId },
    { isDeleted: true },
    { new: true }
  );
  
  if (!reminder) {
    throw new AppError('Reminder not found', 404, 'REMINDER_NOT_FOUND');
  }
  
  auditLog('REMINDER_DELETED', req.userId, { reminderId, shopId });
  
  res.json({
    success: true,
    message: 'Reminder deleted successfully',
  });
});

/**
 * Mark reminder as acknowledged
 * POST /api/shops/:shopId/reminders/:reminderId/acknowledge
 */
const acknowledgeReminder = asyncHandler(async (req, res) => {
  const { shopId, reminderId } = req.params;
  
  const reminder = await Reminder.findOneAndUpdate(
    { _id: reminderId, shopId, status: { $in: ['pending', 'sent'] } },
    { status: 'acknowledged', acknowledgedAt: new Date() },
    { new: true }
  ).populate('customerId', 'name phone');
  
  if (!reminder) {
    throw new AppError('Reminder not found or already processed', 404, 'REMINDER_NOT_FOUND');
  }
  
  res.json({
    success: true,
    message: 'Reminder acknowledged',
    data: { reminder },
  });
});

/**
 * Snooze a reminder
 * POST /api/shops/:shopId/reminders/:reminderId/snooze
 */
const snoozeReminder = asyncHandler(async (req, res) => {
  const { shopId, reminderId } = req.params;
  const { snoozeUntil } = req.body;
  
  const reminder = await Reminder.findOne({
    _id: reminderId,
    shopId,
    isDeleted: false,
  });
  
  if (!reminder) {
    throw new AppError('Reminder not found', 404, 'REMINDER_NOT_FOUND');
  }
  
  if (reminder.snoozeCount >= 3) {
    throw new AppError('Maximum snooze limit reached', 400, 'MAX_SNOOZE_REACHED');
  }
  
  reminder.status = 'snoozed';
  reminder.snoozeUntil = new Date(snoozeUntil);
  reminder.snoozeCount += 1;
  
  await reminder.save();
  await reminder.populate('customerId', 'name phone');
  
  res.json({
    success: true,
    message: 'Reminder snoozed',
    data: { reminder },
  });
});

/**
 * Cancel a reminder
 * POST /api/shops/:shopId/reminders/:reminderId/cancel
 */
const cancelReminder = asyncHandler(async (req, res) => {
  const { shopId, reminderId } = req.params;
  
  const reminder = await Reminder.findOneAndUpdate(
    { _id: reminderId, shopId, status: { $ne: 'cancelled' } },
    { status: 'cancelled' },
    { new: true }
  ).populate('customerId', 'name phone');
  
  if (!reminder) {
    throw new AppError('Reminder not found or already cancelled', 404, 'REMINDER_NOT_FOUND');
  }
  
  res.json({
    success: true,
    message: 'Reminder cancelled',
    data: { reminder },
  });
});

/**
 * Get today's reminders
 * GET /api/shops/:shopId/reminders/today
 */
const getTodayReminders = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  
  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);
  
  const reminders = await Reminder.find({
    shopId,
    isDeleted: false,
    status: 'pending',
    scheduledAt: { $gte: startOfDay, $lte: endOfDay },
  })
    .populate('customerId', 'name phone currentBalance')
    .sort({ scheduledAt: 1 })
    .lean();
  
  res.json({
    success: true,
    data: { reminders },
  });
});

/**
 * Bulk create reminders
 * POST /api/shops/:shopId/reminders/bulk
 */
const bulkCreateReminders = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { customerIds, type, title, message, scheduledAt, reminderChannels, priority } = req.body;
  
  // Verify all customers exist
  const customers = await Customer.find({
    _id: { $in: customerIds },
    shopId,
    isActive: true,
  }).select('_id');
  
  if (customers.length !== customerIds.length) {
    throw new AppError('Some customers not found', 400, 'INVALID_CUSTOMERS');
  }
  
  const reminders = await Reminder.insertMany(
    customerIds.map(customerId => ({
      shopId,
      customerId,
      type,
      title,
      message,
      scheduledAt: new Date(scheduledAt),
      reminderChannels,
      priority,
      createdBy: req.userId,
    }))
  );
  
  auditLog('BULK_REMINDERS_CREATED', req.userId, {
    shopId,
    count: reminders.length,
  });
  
  res.status(201).json({
    success: true,
    message: `${reminders.length} reminders created successfully`,
    data: { count: reminders.length },
  });
});

module.exports = {
  createReminder,
  getReminders,
  getReminder,
  updateReminder,
  deleteReminder,
  acknowledgeReminder,
  snoozeReminder,
  cancelReminder,
  getTodayReminders,
  bulkCreateReminders,
};
