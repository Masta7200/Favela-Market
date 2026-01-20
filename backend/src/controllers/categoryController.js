const Category = require('../models/Category');

// @desc    Get all categories
// @route   GET /api/categories
// @access  Public
exports.getCategories = async (req, res) => {
  try {
    const { active } = req.query;
    const filter = {};

    if (active === 'true') {
      filter.isActive = true;
    }

    const categories = await Category.find(filter).sort({ order: 1, name: 1 });
    res.json({ success: true, data: { categories } });
  } catch (err) {
    console.error('getCategories error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Get single category
// @route   GET /api/categories/:id
// @access  Public
exports.getCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({ success: false, message: 'Catégorie introuvable' });
    }

    res.json({ success: true, data: { category } });
  } catch (err) {
    console.error('getCategory error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Create category
// @route   POST /api/admin/categories
// @access  Private (Admin)
exports.createCategory = async (req, res) => {
  try {
    const { name, description, image, order, isActive } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'Le nom de la catégorie est requis' });
    }

    // Check if category already exists
    const exists = await Category.findOne({ name: { $regex: new RegExp(`^${name}$`, 'i') } });
    if (exists) {
      return res.status(400).json({ success: false, message: 'Cette catégorie existe déjà' });
    }

    const category = await Category.create({
      name,
      description,
      image,
      order: order || 0,
      isActive: isActive !== undefined ? isActive : true
    });

    res.status(201).json({ success: true, data: { category } });
  } catch (err) {
    console.error('createCategory error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Update category
// @route   PUT /api/admin/categories/:id
// @access  Private (Admin)
exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Check for duplicate name
    if (updates.name) {
      const exists = await Category.findOne({
        name: { $regex: new RegExp(`^${updates.name}$`, 'i') },
        _id: { $ne: id }
      });
      if (exists) {
        return res.status(400).json({ success: false, message: 'Cette catégorie existe déjà' });
      }
    }

    const category = await Category.findByIdAndUpdate(id, updates, { new: true, runValidators: true });

    if (!category) {
      return res.status(404).json({ success: false, message: 'Catégorie introuvable' });
    }

    res.json({ success: true, data: { category } });
  } catch (err) {
    console.error('updateCategory error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Delete category
// @route   DELETE /api/admin/categories/:id
// @access  Private (Admin)
exports.deleteCategory = async (req, res) => {
  try {
    const Product = require('../models/Product');

    // Check if any products use this category
    const productCount = await Product.countDocuments({ category: req.params.id });
    if (productCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Impossible de supprimer: ${productCount} produit(s) utilisent cette catégorie`
      });
    }

    const category = await Category.findByIdAndDelete(req.params.id);

    if (!category) {
      return res.status(404).json({ success: false, message: 'Catégorie introuvable' });
    }

    res.json({ success: true, message: 'Catégorie supprimée' });
  } catch (err) {
    console.error('deleteCategory error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Toggle category active status
// @route   PUT /api/admin/categories/:id/toggle-status
// @access  Private (Admin)
exports.toggleCategoryStatus = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({ success: false, message: 'Catégorie introuvable' });
    }

    category.isActive = !category.isActive;
    await category.save();

    res.json({ success: true, data: { category } });
  } catch (err) {
    console.error('toggleCategoryStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
