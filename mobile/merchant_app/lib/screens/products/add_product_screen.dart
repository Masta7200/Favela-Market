import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_button.dart';
import '../../services/cloudinary_service.dart';

class AddProductScreen extends StatefulWidget {
  final String? productId;

  const AddProductScreen({super.key, this.productId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategoryId;
  String? _existingImageUrl;
  String? _uploadedImageUrl;
  File? _pickedImageFile;
  bool _isUploadingImage = false;
  bool _isLoading = false;
  ProductModel? _existingProduct;

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEditing) _loadProduct();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await context.read<ProductProvider>().fetchCategories();
  }

  Future<void> _loadProduct() async {
    final productProvider = context.read<ProductProvider>();
    _existingProduct = productProvider.getProductById(widget.productId!);

    if (_existingProduct != null) {
      setState(() {
        _nameController.text = _existingProduct!.name;
        _descriptionController.text = _existingProduct!.description;
        _priceController.text = _existingProduct!.price.toStringAsFixed(0);
        _stockController.text = _existingProduct!.stock.toString();
        _selectedCategoryId = _existingProduct!.categoryId;
        _existingImageUrl = _existingProduct!.image;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_uploadedImageUrl != null || _existingImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: const Text(
                  'Supprimer l\'image',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _uploadedImageUrl = null;
                    _existingImageUrl = null;
                    _pickedImageFile = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _pickedImageFile = File(picked.path);
      _isUploadingImage = true;
    });

    try {
      final url = await CloudinaryService.uploadImage(picked.path);
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _pickedImageFile = null;
        _isUploadingImage = false;
      });
    } on CloudinaryNotConfiguredException {
      if (!mounted) return;
      setState(() {
        _pickedImageFile = null;
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le stockage d\'images n\'est pas encore configuré. Contactez l\'administrateur.',
          ),
          backgroundColor: AppTheme.warningColor,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickedImageFile = null;
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final productProvider = context.read<ProductProvider>();
    final imageUrl = _uploadedImageUrl ?? _existingImageUrl;

    bool success;
    if (isEditing) {
      success = await productProvider.updateProduct(
        productId: widget.productId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        stock: int.parse(_stockController.text.trim()),
        image: imageUrl,
      );
    } else {
      success = await productProvider.addProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        stock: int.parse(_stockController.text.trim()),
        image: imageUrl,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Produit mis à jour avec succès'
                : 'Produit ajouté! En attente d\'approbation.',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.error ?? 'Erreur lors de l\'enregistrement'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;
    final displayImageUrl = _uploadedImageUrl ?? _existingImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              _buildLabel('Photo du produit'),
              GestureDetector(
                onTap: _isUploadingImage ? null : _showImagePickerOptions,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUploadingImage
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: _isUploadingImage
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_pickedImageFile != null)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.file(
                                    _pickedImageFile!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            Container(
                              color: Colors.black45,
                              padding: const EdgeInsets.all(12),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Téléchargement en cours...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : displayImageUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    displayImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildImagePlaceholder(hasError: true),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 20),

              // Product Name
              _buildLabel('Nom du produit'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ex: T-shirt Nike Original',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du produit';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Décrivez votre produit en détail...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  if (value.length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel('Catégorie'),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  hintText: 'Sélectionnez une catégorie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((CategoryModel category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price and Stock Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Prix (FCFA)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Ex: 5000',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez le prix';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Prix invalide';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Stock'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Ex: 10',
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez le stock';
                            }
                            final stock = int.tryParse(value);
                            if (stock == null || stock < 0) {
                              return 'Stock invalide';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: AppTheme.warningColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre produit sera vérifié par notre équipe avant d\'être visible aux clients.',
                          style: TextStyle(
                            color: AppTheme.warningColor.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              CustomButton(
                text: isEditing ? 'Mettre à jour' : 'Ajouter le produit',
                onPressed: _saveProduct,
                isLoading: _isLoading || productProvider.isLoading,
                gradient: AppTheme.primaryGradient,
                icon: isEditing ? Icons.save : Icons.add,
              ),
              const SizedBox(height: 16),

              CustomButton(
                text: 'Annuler',
                onPressed: () => context.pop(),
                outlined: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({bool hasError = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hasError ? Icons.broken_image_outlined : Icons.add_a_photo_outlined,
          size: 48,
          color: hasError ? Colors.grey[400] : AppTheme.primaryColor.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          hasError ? 'Impossible de charger l\'image' : 'Appuyez pour ajouter une photo',
          style: TextStyle(
            color: hasError ? Colors.grey[500] : AppTheme.primaryColor.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        if (!hasError) ...[
          const SizedBox(height: 4),
          Text(
            'Galerie ou caméra',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }
}
