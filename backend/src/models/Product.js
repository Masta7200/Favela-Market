const mongoose = require('mongoose');
const { PRODUCT_STATUS } = require('../constants');

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Le nom du produit est requis'],
    trim: true
  },
  description: {
    type: String,
    required: [true, 'La description est requise'],
    trim: true
  },
  price: {
    type: Number,
    required: [true, 'Le prix est requis'],
    min: [0, 'Le prix doit être positif']
  },
  comparePrice: {
    type: Number,
    min: [0, 'Le prix de comparaison doit être positif']
  },
  stock: {
    type: Number,
    required: [true, 'Le stock est requis'],
    min: [0, 'Le stock doit être positif'],
    default: 0
  },
  images: [{
    type: String
  }],
  image: {
    type: String
  },
  category: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: [true, 'La catégorie est requise']
  },
  merchant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Le marchand est requis']
  },
  status: {
    type: String,
    enum: Object.values(PRODUCT_STATUS),
    default: PRODUCT_STATUS.PENDING
  },
  isApproved: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  rejectionReason: {
    type: String
  },
  // Additional product details
  specifications: [{
    key: String,
    value: String
  }],
  tags: [{
    type: String,
    trim: true
  }],
  // Stats
  views: {
    type: Number,
    default: 0
  },
  soldCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Index for search
productSchema.index({ name: 'text', description: 'text', tags: 'text' });

// Virtual for category name (populated)
productSchema.virtual('categoryName', {
  ref: 'Category',
  localField: 'category',
  foreignField: '_id',
  justOne: true
});

// Virtual for merchant name (populated)
productSchema.virtual('merchantName', {
  ref: 'User',
  localField: 'merchant',
  foreignField: '_id',
  justOne: true
});

// Ensure virtuals are included in JSON
productSchema.set('toJSON', { virtuals: true });
productSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Product', productSchema);
