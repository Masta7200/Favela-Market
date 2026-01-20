const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Protect middleware - verifies JWT and attaches user to request
exports.protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({ success: false, message: 'Non autorisé, token manquant' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({ success: false, message: 'Utilisateur introuvable' });
    }

    if (!user.isActive) {
      return res.status(401).json({ success: false, message: 'Compte désactivé' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token invalide' });
  }
};

// Authorize middleware - checks user role
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || (roles.length && !roles.includes(req.user.role))) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }
    next();
  };
};