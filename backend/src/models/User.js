const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { USER_ROLES } = require('../constants');

const userSchema = new mongoose.Schema({
  phone: {
    type: String,
    required: [true, 'Le numéro de téléphone est requis'],
    unique: true,
    trim: true,
    match: [/^\+?[1-9]\d{1,14}$/, 'Numéro de téléphone invalide']
  },
  password: {
    type: String,
    required: [true, 'Le mot de passe est requis'],
    minlength: [6, 'Le mot de passe doit contenir au moins 6 caractères'],
    select: false
  },
  name: {
    type: String,
    required: [true, 'Le nom est requis'],
    trim: true
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    sparse: true,
    match: [/^\S+@\S+\.\S+$/, 'Email invalide']
  },
  role: {
    type: String,
    enum: Object.values(USER_ROLES),
    default: USER_ROLES.CLIENT
  },
  
  // Client specific fields
  addresses: [{
    label: String,        // Maison, Bureau, etc.
    fullAddress: String,
    city: String,
    quarter: String,      // Quartier
    details: String,      // Instructions supplémentaires
    isDefault: {
      type: Boolean,
      default: false
    }
  }],
  
  // Merchant specific fields
  shopName: {
    type: String,
    trim: true
  },
  shopDescription: {
    type: String
  },
  shopAddress: {
    type: String
  },
  shopPhone: {
    type: String
  },
  isApproved: {
    type: Boolean,
    default: false
  },
  
  // Delivery specific fields
  vehicleType: {
    type: String,
    enum: ['moto', 'velo', 'voiture']
  },
  vehicleNumber: {
    type: String
  },
  
  // General fields
  avatar: {
    type: String
  },
  isActive: {
    type: Boolean,
    default: true
  },
  fcmToken: {
    type: String  // For push notifications
  },
  otp: {
    code: String,
    expiresAt: Date
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre("save", async function () {
  if (!this.isModified("password")) return;

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Generate JWT token
userSchema.methods.generateAuthToken = function() {
  const secret = process.env.JWT_SECRET || 'favela_default_jwt_secret_change_me';
  const expiresIn = process.env.JWT_EXPIRE || '7d';

  return jwt.sign(
    {
      id: this._id,
      role: this.role,
      phone: this.phone
    },
    secret,
    { expiresIn }
  );
};

// Generate OTP
userSchema.methods.generateOTP = function() {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  this.otp = {
    code: otp,
    expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
  };
  return otp;
};

// Verify OTP
userSchema.methods.verifyOTP = function(candidateOTP) {
  if (!this.otp || !this.otp.code) {
    return false;
  }
  
  if (new Date() > this.otp.expiresAt) {
    return false;
  }
  
  return this.otp.code === candidateOTP;
};

module.exports = mongoose.model('User', userSchema);