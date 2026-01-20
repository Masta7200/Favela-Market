const Product = require('../models/Product');
const Category = require('../models/Category');
const { PRODUCT_STATUS, USER_ROLES } = require('../constants');

// @desc    Get all products (Admin)
// @route   GET /api/admin/products
// @access  Private (Admin)
exports.getProducts = async (req, res) => {
  try {
    const { status, category, merchant, search } = req.query;
    const filter = {};

    if (status && status !== 'all') {
      if (status === 'pending') {
        filter.isApproved = false;
        filter.status = PRODUCT_STATUS.PENDING;
      } else if (status === 'approved') {
        filter.isApproved = true;
        filter.status = PRODUCT_STATUS.APPROVED;
      } else if (status === 'rejected') {
        filter.status = PRODUCT_STATUS.REJECTED;
      }
    }

    if (category) filter.category = category;
    if (merchant) filter.merchant = merchant;

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const products = await Product.find(filter)
      .populate('category', 'name')
      .populate('merchant', 'name shopName')
      .sort({ createdAt: -1 });

    // Map to include categoryName and merchantName
    const mappedProducts = products.map(p => ({
      ...p.toObject(),
      categoryName: p.category?.name || 'Non catégorisé',
      merchantName: p.merchant?.shopName || p.merchant?.name || 'Inconnu'
    }));

    res.json({ success: true, data: { products: mappedProducts } });
  } catch (err) {
    console.error('getProducts error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Get single product
// @route   GET /api/admin/products/:id
// @access  Private (Admin)
exports.getProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('category', 'name')
      .populate('merchant', 'name shopName phone');

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable' });
    }

    res.json({ success: true, data: { product } });
  } catch (err) {
    console.error('getProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Create product (Admin can create for any merchant)
// @route   POST /api/admin/products
// @access  Private (Admin)
exports.createProduct = async (req, res) => {
  try {
    const { name, description, price, comparePrice, stock, image, images, category, merchant, tags, specifications } = req.body;

    if (!name || !description || !price || !category || !merchant) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }

    // Verify category exists
    const categoryExists = await Category.findById(category);
    if (!categoryExists) {
      return res.status(400).json({ success: false, message: 'Catégorie invalide' });
    }

    const product = await Product.create({
      name,
      description,
      price,
      comparePrice,
      stock: stock || 0,
      image,
      images: images || [],
      category,
      merchant,
      tags: tags || [],
      specifications: specifications || [],
      status: PRODUCT_STATUS.APPROVED, // Admin-created products are auto-approved
      isApproved: true
    });

    res.status(201).json({ success: true, data: { product } });
  } catch (err) {
    console.error('createProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Update product
// @route   PUT /api/admin/products/:id
// @access  Private (Admin)
exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const product = await Product.findByIdAndUpdate(id, updates, { new: true, runValidators: true })
      .populate('category', 'name')
      .populate('merchant', 'name shopName');

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable' });
    }

    res.json({ success: true, data: { product } });
  } catch (err) {
    console.error('updateProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Delete product
// @route   DELETE /api/admin/products/:id
// @access  Private (Admin)
exports.deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable' });
    }

    res.json({ success: true, message: 'Produit supprimé' });
  } catch (err) {
    console.error('deleteProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Approve product
// @route   PUT /api/admin/products/:id/approve
// @access  Private (Admin)
exports.approveProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable' });
    }

    product.isApproved = true;
    product.status = PRODUCT_STATUS.APPROVED;
    product.rejectionReason = undefined;
    await product.save();

    res.json({ success: true, message: 'Produit approuvé', data: { product } });
  } catch (err) {
    console.error('approveProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Reject product
// @route   PUT /api/admin/products/:id/reject
// @access  Private (Admin)
exports.rejectProduct = async (req, res) => {
  try {
    const { reason } = req.body;
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable' });
    }

    product.isApproved = false;
    product.status = PRODUCT_STATUS.REJECTED;
    product.rejectionReason = reason || 'Non conforme aux règles de la plateforme';
    await product.save();

    res.json({ success: true, message: 'Produit rejeté', data: { product } });
  } catch (err) {
    console.error('rejectProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== MERCHANT ROUTES ====================

// @desc    Get merchant's products
// @route   GET /api/products/my-products
// @access  Private (Merchant)
exports.getMerchantProducts = async (req, res) => {
  try {
    const { status, search } = req.query;
    const filter = { merchant: req.user._id };

    if (status && status !== 'all') {
      filter.status = status;
    }

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const products = await Product.find(filter)
      .populate('category', 'name')
      .sort({ createdAt: -1 });

    const mappedProducts = products.map(p => ({
      ...p.toObject(),
      categoryName: p.category?.name || 'Non catégorisé'
    }));

    res.json({ success: true, data: { products: mappedProducts } });
  } catch (err) {
    console.error('getMerchantProducts error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Create product (Merchant)
// @route   POST /api/products
// @access  Private (Merchant)
exports.createMerchantProduct = async (req, res) => {
  try {
    const { name, description, price, comparePrice, stock, image, images, category, tags, specifications } = req.body;

    if (!name || !description || !price || !category) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }

    // Verify merchant is approved
    if (!req.user.isApproved) {
      return res.status(403).json({ success: false, message: 'Votre compte marchand doit être approuvé pour ajouter des produits' });
    }

    // Verify category exists
    const categoryExists = await Category.findById(category);
    if (!categoryExists) {
      return res.status(400).json({ success: false, message: 'Catégorie invalide' });
    }

    const product = await Product.create({
      name,
      description,
      price,
      comparePrice,
      stock: stock || 0,
      image,
      images: images || [],
      category,
      merchant: req.user._id,
      tags: tags || [],
      specifications: specifications || [],
      status: PRODUCT_STATUS.PENDING, // Merchant products need approval
      isApproved: false
    });

    res.status(201).json({ success: true, message: 'Produit créé, en attente d\'approbation', data: { product } });
  } catch (err) {
    console.error('createMerchantProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Update merchant's product
// @route   PUT /api/products/:id
// @access  Private (Merchant)
exports.updateMerchantProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Find and verify ownership
    const product = await Product.findOne({ _id: id, merchant: req.user._id });

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable ou non autorisé' });
    }

    // Update allowed fields
    const allowedUpdates = ['name', 'description', 'price', 'comparePrice', 'stock', 'image', 'images', 'category', 'tags', 'specifications', 'isActive'];
    allowedUpdates.forEach(field => {
      if (updates[field] !== undefined) {
        product[field] = updates[field];
      }
    });

    // If significant changes, may need re-approval
    if (updates.name || updates.description || updates.price) {
      product.status = PRODUCT_STATUS.PENDING;
      product.isApproved = false;
    }

    await product.save();

    res.json({ success: true, data: { product } });
  } catch (err) {
    console.error('updateMerchantProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Delete merchant's product
// @route   DELETE /api/products/:id
// @access  Private (Merchant)
exports.deleteMerchantProduct = async (req, res) => {
  try {
    const product = await Product.findOneAndDelete({ _id: req.params.id, merchant: req.user._id });

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable ou non autorisé' });
    }

    res.json({ success: true, message: 'Produit supprimé' });
  } catch (err) {
    console.error('deleteMerchantProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== PUBLIC ROUTES ====================

// @desc    Get all approved products (Public)
// @route   GET /api/products
// @access  Public
exports.getPublicProducts = async (req, res) => {
  try {
    const { category, search, minPrice, maxPrice, sort, page = 1, limit = 20 } = req.query;
    const filter = { isApproved: true, isActive: true, status: PRODUCT_STATUS.APPROVED };

    if (category) filter.category = category;

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { tags: { $regex: search, $options: 'i' } }
      ];
    }

    if (minPrice || maxPrice) {
      filter.price = {};
      if (minPrice) filter.price.$gte = Number(minPrice);
      if (maxPrice) filter.price.$lte = Number(maxPrice);
    }

    let sortOption = { createdAt: -1 };
    if (sort === 'price_asc') sortOption = { price: 1 };
    else if (sort === 'price_desc') sortOption = { price: -1 };
    else if (sort === 'popular') sortOption = { soldCount: -1 };

    const skip = (Number(page) - 1) * Number(limit);

    const products = await Product.find(filter)
      .populate('category', 'name')
      .populate('merchant', 'shopName')
      .sort(sortOption)
      .skip(skip)
      .limit(Number(limit));

    const total = await Product.countDocuments(filter);

    const mappedProducts = products.map(p => ({
      ...p.toObject(),
      categoryName: p.category?.name || 'Non catégorisé',
      merchantName: p.merchant?.shopName || 'Inconnu'
    }));

    res.json({
      success: true,
      data: {
        products: mappedProducts,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          pages: Math.ceil(total / Number(limit))
        }
      }
    });
  } catch (err) {
    console.error('getPublicProducts error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Get single product (Public)
// @route   GET /api/products/:id
// @access  Public
exports.getPublicProduct = async (req, res) => {
  try {
    const product = await Product.findOne({
      _id: req.params.id,
      isApproved: true,
      isActive: true
    })
      .populate('category', 'name')
      .populate('merchant', 'shopName shopPhone');

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit introuvable' });
    }

    // Increment views
    product.views += 1;
    await product.save();

    res.json({ success: true, data: { product } });
  } catch (err) {
    console.error('getPublicProduct error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
