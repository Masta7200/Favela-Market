const User = require('../models/User');
const { USER_ROLES } = require('../constants');

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { phone, password, name, role, email } = req.body;

    // Validate required fields
    if (!phone || !password || !name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Veuillez fournir le téléphone, le mot de passe, le nom et l\'email'
      });
    }

    // Check if user already exists
    const userExists = await User.findOne({ phone });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'Ce numéro de téléphone est déjà enregistré'
      });
    }

    // Set default role to client if not specified or invalid
    let userRole = USER_ROLES.CLIENT;
    if (role && Object.values(USER_ROLES).includes(role) && role !== USER_ROLES.ADMIN) {
      userRole = role;
    }

    // Create user
    const user = await User.create({
      phone,
      password,
      name,
      email,
      role: userRole
    });

    // Generate token
    const token = user.generateAuthToken();

    res.status(201).json({
      success: true,
      message: 'Inscription réussie',
      data: {
        token,
        user: {
          id: user._id,
          phone: user.phone,
          name: user.name,
          email: user.email,
          role: user.role,
          isApproved: user.isApproved,
          isActive: user.isActive
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Request password reset (generate OTP)
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ success: false, message: 'Veuillez fournir le numéro de téléphone' });
    }

    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    const otp = user.generateOTP();
    await user.save();

    // TODO: integrate SMS/email provider to send OTP. For now return OTP in response for testing.
    res.status(200).json({
      success: true,
      message: 'Code OTP envoyé',
      data: { otp: otp }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reset password using OTP
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res, next) => {
  try {
    const { phone, otp, newPassword } = req.body;

    if (!phone || !otp || !newPassword) {
      return res.status(400).json({ success: false, message: 'Téléphone, OTP et nouveau mot de passe requis' });
    }

    const user = await User.findOne({ phone }).select('+password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    const isValid = user.verifyOTP(otp);
    if (!isValid) {
      return res.status(400).json({ success: false, message: 'OTP invalide ou expiré' });
    }

    user.password = newPassword;
    user.otp = undefined;
    await user.save();

    const token = user.generateAuthToken();

    res.status(200).json({
      success: true,
      message: 'Mot de passe réinitialisé avec succès',
      data: { token }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { phone, password } = req.body;

    // Validate fields
    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Veuillez fournir le téléphone et le mot de passe'
      });
    }

    // Find user and include password
    const user = await User.findOne({ phone }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Identifiants invalides'
      });
    }

    // Check password
    const isPasswordMatch = await user.comparePassword(password);

    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Identifiants invalides'
      });
    }

    // Check if account is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Votre compte a été désactivé'
      });
    }

    // Generate token
    const token = user.generateAuthToken();

    res.status(200).json({
      success: true,
      message: 'Connexion réussie',
      data: {
        token,
        user: {
          id: user._id,
          phone: user.phone,
          name: user.name,
          email: user.email,
          role: user.role,
          isApproved: user.isApproved,
          isActive: user.isActive,
          shopName: user.shopName,
          avatar: user.avatar,
          addresses: user.addresses
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          phone: user.phone,
          name: user.name,
          email: user.email,
          role: user.role,
          isApproved: user.isApproved,
          isActive: user.isActive,
          shopName: user.shopName,
          shopDescription: user.shopDescription,
          shopAddress: user.shopAddress,
          shopPhone: user.shopPhone,
          avatar: user.avatar,
          addresses: user.addresses,
          vehicleType: user.vehicleType,
          vehicleNumber: user.vehicleNumber,
          createdAt: user.createdAt
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
exports.updateProfile = async (req, res, next) => {
  try {
    const fieldsToUpdate = {
      name: req.body.name,
      email: req.body.email
    };

    // Role-specific updates
    if (req.user.role === USER_ROLES.MERCHANT) {
      fieldsToUpdate.shopName = req.body.shopName;
      fieldsToUpdate.shopDescription = req.body.shopDescription;
      fieldsToUpdate.shopAddress = req.body.shopAddress;
      fieldsToUpdate.shopPhone = req.body.shopPhone;
    }

    if (req.user.role === USER_ROLES.DELIVERY) {
      fieldsToUpdate.vehicleType = req.body.vehicleType;
      fieldsToUpdate.vehicleNumber = req.body.vehicleNumber;
    }

    // Remove undefined fields
    Object.keys(fieldsToUpdate).forEach(
      key => fieldsToUpdate[key] === undefined && delete fieldsToUpdate[key]
    );

    const user = await User.findByIdAndUpdate(
      req.user.id,
      fieldsToUpdate,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data: { user }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update password
// @route   PUT /api/auth/password
// @access  Private
exports.updatePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Veuillez fournir le mot de passe actuel et le nouveau mot de passe'
      });
    }

    const user = await User.findById(req.user.id).select('+password');

    // Check current password
    const isPasswordMatch = await user.comparePassword(currentPassword);
    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Mot de passe actuel incorrect'
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    const token = user.generateAuthToken();

    res.status(200).json({
      success: true,
      message: 'Mot de passe mis à jour avec succès',
      data: { token }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add address (for clients)
// @route   POST /api/auth/addresses
// @access  Private (Client only)
exports.addAddress = async (req, res, next) => {
  try {
    const { label, fullAddress, city, quarter, details, isDefault } = req.body;

    if (!fullAddress || !city) {
      return res.status(400).json({
        success: false,
        message: 'L\'adresse complète et la ville sont requises'
      });
    }

    const user = await User.findById(req.user.id);

    // If this is default, set all others to non-default
    if (isDefault) {
      user.addresses.forEach(addr => addr.isDefault = false);
    }

    // If this is the first address, make it default
    const makeDefault = user.addresses.length === 0 || isDefault;

    user.addresses.push({
      label,
      fullAddress,
      city,
      quarter,
      details,
      isDefault: makeDefault
    });

    await user.save();

    res.status(201).json({
      success: true,
      message: 'Adresse ajoutée avec succès',
      data: { addresses: user.addresses }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update FCM token for notifications
// @route   POST /api/auth/fcm-token
// @access  Private
exports.updateFCMToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'Token FCM requis'
      });
    }

    await User.findByIdAndUpdate(req.user.id, { fcmToken });

    res.status(200).json({
      success: true,
      message: 'Token FCM mis à jour'
    });
  } catch (error) {
    next(error);
  }
};