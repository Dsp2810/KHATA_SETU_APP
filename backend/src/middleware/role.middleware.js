const { Shop } = require('../models');

/**
 * Role-based access control middleware
 * @param  {...string} allowedRoles - Roles that are allowed to access the route
 */
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
        code: 'NOT_AUTHENTICATED',
      });
    }
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to perform this action.',
        code: 'FORBIDDEN',
      });
    }
    
    next();
  };
};

/**
 * Shop owner authorization middleware
 * Ensures the user owns or has access to the shop
 */
const authorizeShopAccess = async (req, res, next) => {
  try {
    const shopId = req.params.shopId || req.body.shopId || req.query.shopId;
    
    if (!shopId) {
      return res.status(400).json({
        success: false,
        message: 'Shop ID is required.',
        code: 'SHOP_ID_REQUIRED',
      });
    }
    
    const shop = await Shop.findById(shopId);
    
    if (!shop) {
      return res.status(404).json({
        success: false,
        message: 'Shop not found.',
        code: 'SHOP_NOT_FOUND',
      });
    }
    
    // Check if user is owner
    const isOwner = shop.owner.toString() === req.userId.toString();
    
    // Check if user is employee with access
    const employee = shop.employees.find(
      emp => emp.userId && emp.userId.toString() === req.userId.toString() && emp.isActive
    );
    
    if (!isOwner && !employee) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this shop.',
        code: 'SHOP_ACCESS_DENIED',
      });
    }
    
    // Attach shop and role info to request
    req.shop = shop;
    req.shopRole = isOwner ? 'owner' : 'employee';
    req.shopPermissions = isOwner 
      ? ['all'] 
      : employee.permissions;
    
    next();
  } catch (error) {
    console.error('Shop authorization error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during authorization.',
      code: 'AUTH_ERROR',
    });
  }
};

/**
 * Permission check middleware
 * Checks if user has specific permission for shop operations
 * @param {string} permission - Required permission
 */
const requirePermission = (permission) => {
  return (req, res, next) => {
    if (!req.shopPermissions) {
      return res.status(403).json({
        success: false,
        message: 'Shop access required.',
        code: 'SHOP_ACCESS_REQUIRED',
      });
    }
    
    // Owner has all permissions
    if (req.shopPermissions.includes('all')) {
      return next();
    }
    
    if (!req.shopPermissions.includes(permission)) {
      return res.status(403).json({
        success: false,
        message: `You need '${permission}' permission to perform this action.`,
        code: 'PERMISSION_DENIED',
      });
    }
    
    next();
  };
};

/**
 * Admin only middleware
 */
const adminOnly = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required.',
      code: 'NOT_AUTHENTICATED',
    });
  }
  
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Admin access required.',
      code: 'ADMIN_REQUIRED',
    });
  }
  
  next();
};

module.exports = {
  authorize,
  authorizeShopAccess,
  requirePermission,
  adminOnly,
};
