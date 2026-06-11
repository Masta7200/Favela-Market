const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  orderNumber: {
    type: String,
    required: true,
    unique: true
  },
  client: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Le client est requis']
  },
  merchant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Le marchand est requis']
  },
  items: [{
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true
    },
    quantity: {
      type: Number,
      required: true,
      min: 1
    },
    price: {
      type: Number,
      required: true
    },
    subtotal: {
      type: Number,
      required: true
    }
  }],
  total: {
    type: Number,
    required: [true, 'Le total est requis'],
    min: 0
  },
  deliveryAddress: {
    type: String,
    required: true
  },
  deliveryPhone: {
    type: String
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'preparing', 'ready', 'in_transit', 'delivered', 'cancelled', 'completed'],
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'mobile_money', 'card'],
    default: 'cash'
  },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'paid', 'refunded'],
    default: 'unpaid'
  },
  notes: {
    type: String
  },
  deliveredAt: {
    type: Date
  },
  cancelledAt: {
    type: Date
  },
  cancelReason: {
    type: String
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

// Auto-increment order number
orderSchema.pre('validate', async function() {
  if (!this.orderNumber) {
    const lastOrder = await this.constructor.findOne({ orderNumber: { $exists: true } }).sort({ _id: -1 });
    const lastNumber = lastOrder && lastOrder.orderNumber
      ? parseInt(lastOrder.orderNumber.replace('ORD-', ''))
      : 0;
    this.orderNumber = `ORD-${String(lastNumber + 1).padStart(6, '0')}`;
  }
});

module.exports = mongoose.model('Order', orderSchema);
