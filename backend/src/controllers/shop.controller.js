const { Shop } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');

/**
 * Create a new shop
 * POST /api/shops
 */
const createShop = asyncHandler(async (req, res) => {
  const shopData = {
    ...req.body,
    owner: req.userId,
  };
  
  const shop = await Shop.create(shopData);
  
  auditLog('SHOP_CREATED', req.userId, { shopId: shop._id });
  
  res.status(201).json({
    success: true,
    message: 'Shop created successfully',
    data: { shop },
  });
});

/**
 * Get all shops for current user
 * GET /api/shops
 */
const getShops = asyncHandler(async (req, res) => {
  const shops = await Shop.find({
    $or: [
      { owner: req.userId },
      { 'employees.userId': req.userId, 'employees.isActive': true },
    ],
  })
    .populate('owner', 'name phone')
    .lean();
  
  // Add role info for each shop
  const shopsWithRole = shops.map(shop => ({
    ...shop,
    userRole: shop.owner._id.toString() === req.userId.toString() ? 'owner' : 'employee',
  }));
  
  res.json({
    success: true,
    data: { shops: shopsWithRole },
  });
});

/**
 * Get a single shop
 * GET /api/shops/:shopId
 */
const getShop = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const shop = await Shop.findById(shopId)
    .populate('owner', 'name phone email');
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { shop },
  });
});

/**
 * Update shop
 * PATCH /api/shops/:shopId
 */
const updateShop = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  // Don't allow changing owner
  delete req.body.owner;
  
  const shop = await Shop.findByIdAndUpdate(
    shopId,
    req.body,
    { new: true, runValidators: true }
  );
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  auditLog('SHOP_UPDATED', req.userId, {
    shopId,
    updates: Object.keys(req.body),
  });
  
  res.json({
    success: true,
    message: 'Shop updated successfully',
    data: { shop },
  });
});

/**
 * Delete shop
 * DELETE /api/shops/:shopId
 */
const deleteShop = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const shop = await Shop.findById(shopId);
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  // Only owner can delete
  if (shop.owner.toString() !== req.userId.toString()) {
    throw new AppError('Only shop owner can delete the shop', 403, 'NOT_OWNER');
  }
  
  shop.isActive = false;
  await shop.save();
  
  auditLog('SHOP_DELETED', req.userId, { shopId });
  
  res.json({
    success: true,
    message: 'Shop deleted successfully',
  });
});

/**
 * Add employee to shop
 * POST /api/shops/:shopId/employees
 */
const addEmployee = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { userId, permissions, name, phone } = req.body;
  
  const shop = await Shop.findById(shopId);
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  // Check if already an employee
  const existingEmployee = userId ? shop.employees.find(
    emp => emp.userId && emp.userId.toString() === userId.toString()
  ) : null;
  
  if (existingEmployee) {
    throw new AppError('User is already an employee', 400, 'ALREADY_EMPLOYEE');
  }
  
  shop.employees.push({
    userId,
    name,
    phone,
    permissions: permissions || ['view_customers', 'view_ledger'],
    isActive: true,
    addedAt: new Date(),
  });
  
  await shop.save();
  
  auditLog('EMPLOYEE_ADDED', req.userId, {
    shopId,
    employeeUserId: userId,
  });
  
  res.status(201).json({
    success: true,
    message: 'Employee added successfully',
    data: { shop },
  });
});

/**
 * Update employee permissions
 * PATCH /api/shops/:shopId/employees/:employeeId
 */
const updateEmployee = asyncHandler(async (req, res) => {
  const { shopId, employeeId } = req.params;
  const { permissions, isActive } = req.body;
  
  const shop = await Shop.findById(shopId);
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  const employee = shop.employees.id(employeeId);
  
  if (!employee) {
    throw new AppError('Employee not found', 404, 'EMPLOYEE_NOT_FOUND');
  }
  
  if (permissions) {
    employee.permissions = permissions;
  }
  
  if (typeof isActive === 'boolean') {
    employee.isActive = isActive;
  }
  
  await shop.save();
  
  auditLog('EMPLOYEE_UPDATED', req.userId, {
    shopId,
    employeeId,
  });
  
  res.json({
    success: true,
    message: 'Employee updated successfully',
    data: { employee },
  });
});

/**
 * Remove employee from shop
 * DELETE /api/shops/:shopId/employees/:employeeId
 */
const removeEmployee = asyncHandler(async (req, res) => {
  const { shopId, employeeId } = req.params;
  
  const shop = await Shop.findById(shopId);
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  const employee = shop.employees.id(employeeId);
  
  if (!employee) {
    throw new AppError('Employee not found', 404, 'EMPLOYEE_NOT_FOUND');
  }
  
  employee.remove();
  await shop.save();
  
  auditLog('EMPLOYEE_REMOVED', req.userId, {
    shopId,
    employeeId,
  });
  
  res.json({
    success: true,
    message: 'Employee removed successfully',
  });
});

/**
 * Get shop employees
 * GET /api/shops/:shopId/employees
 */
const getEmployees = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const shop = await Shop.findById(shopId)
    .populate('employees.userId', 'name phone email avatar');
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { employees: shop.employees },
  });
});

/**
 * Update shop settings
 * PATCH /api/shops/:shopId/settings
 */
const updateSettings = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const shop = await Shop.findByIdAndUpdate(
    shopId,
    { settings: req.body },
    { new: true, runValidators: true }
  );
  
  if (!shop) {
    throw new AppError('Shop not found', 404, 'SHOP_NOT_FOUND');
  }
  
  res.json({
    success: true,
    message: 'Settings updated successfully',
    data: { settings: shop.settings },
  });
});

module.exports = {
  createShop,
  getShops,
  getShop,
  updateShop,
  deleteShop,
  addEmployee,
  updateEmployee,
  removeEmployee,
  getEmployees,
  updateSettings,
};
