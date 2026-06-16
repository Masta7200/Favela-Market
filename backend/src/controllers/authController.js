const User = require('../models/User');
const { USER_ROLES } = require('../constants');
const sendEmail = require('../utils/sendEmail');

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
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Veuillez fournir votre adresse email' });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à cet email' });
    }

    const otp = user.generateOTP();

    try {
      await sendEmail({
        to: user.email,
        subject: 'Tumai Market - Code de réinitialisation du mot de passe',
        html: `
          <p>Bonjour ${user.name || ''},</p>
          <p>Voici votre code de réinitialisation de mot de passe :</p>
          <h2 style="letter-spacing:4px;">${otp}</h2>
          <p>Ce code est valable pendant 10 minutes.</p>
          <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
        `
      });
    } catch (emailError) {
      console.error('forgotPassword sendEmail error', emailError);
      return res.status(500).json({
        success: false,
        message: 'Impossible d\'envoyer l\'email de réinitialisation. Veuillez réessayer plus tard.'
      });
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Un code a été envoyé à votre adresse email',
      data: {
        // Only expose the OTP outside production, to ease local testing
        ...(process.env.NODE_ENV !== 'production' ? { otp } : {})
      }
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
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ success: false, message: 'Email, OTP et nouveau mot de passe requis' });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() }).select('+password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à cet email' });
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

exports.requestPasswordReset = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email est requis' });
    }

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    user.resetOtp = otp;
    user.resetOtpExpiry = otpExpiry;
    await user.save();

    // Send OTP to email
    await sendEmail(user.email, 'Réinitialiser votre mot de passe', `Votre code OTP: ${otp}`);

    res.json({
      success: true,
      message: 'Code envoyé à votre email',
      maskedEmail: maskEmail(user.email)
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};