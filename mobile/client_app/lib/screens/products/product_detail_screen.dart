import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/products.dart';
import '../../providers/cart.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productProvider = context.read<ProductProvider>();
    final product = await productProvider.getProductById(widget.productId);

    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du produit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du produit')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Produit non trouvé'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final isInCart = cartProvider.isInCart(_product!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: _product!.image != null
                  ? CachedNetworkImage(
                      imageUrl: _product!.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag,
                      size: 80,
                      color: Colors.grey,
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    _product!.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),

                  // Category
                  Chip(
                    label: Text(_product!.categoryName),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    '${_product!.price.toStringAsFixed(0)} ${AppConfig.currency}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        _product!.isAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _product!.isAvailable
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _product!.isAvailable
                            ? 'En stock (${_product!.stock} disponibles)'
                            : 'Rupture de stock',
                        style: TextStyle(
                          color: _product!.isAvailable
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Merchant Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vendu par',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            Text(
                              _product!.merchantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector (if not in cart)
                  if (!isInCart && _product!.isAvailable) ...[
                    Text(
                      'Quantité',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.primaryColor,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_quantity',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < _product!.stock
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _product!.isAvailable
              ? CustomButton(
                  text: isInCart ? 'Voir le panier' : 'Ajouter au panier',
                  gradient: isInCart
                      ? AppTheme.accentGradient
                      : AppTheme.primaryGradient,
                  icon:
                      isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                  onPressed: () {
                    if (isInCart) {
                      context.push('/cart');
                    } else {
                      cartProvider.addItem(_product!, quantity: _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '$_quantity ${_product!.name} ajouté(s) au panier'),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                )
              : CustomButton(
                  text: 'Produit indisponible',
                  backgroundColor: Colors.grey,
                  onPressed: null,
                ),
        ),
      ),
    );
  }
}
