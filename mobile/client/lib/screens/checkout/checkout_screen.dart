import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/cart.dart';
import '../../providers/auth.dart';
import '../../providers/order_provider.dart';
import '../../models/usermodel.dart';
import '../../models/order_model.dart';
import '../../widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  final TextEditingController _notesController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.addresses != null &&
        authProvider.user!.addresses!.isNotEmpty) {
      _selectedAddress = authProvider.user!.addresses!.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => authProvider.user!.addresses!.first);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse de livraison'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Convert cart items to order items
    final orderItems = cartProvider.items.map((item) {
      return OrderItemModel(
        productId: item.product.id,
        productName: item.product.name,
        productImage: item.product.image,
        price: item.product.price,
        quantity: item.quantity,
        subtotal: item.subtotal,
      );
    }).toList();

    final order = await orderProvider.createOrder(
      items: orderItems,
      deliveryAddress: _selectedAddress!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isPlacingOrder = false);

    if (order != null) {
      // Clear cart
      await cartProvider.clearCart();

      // Show success and navigate
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande passée avec succès!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      context.go('/order/${order.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Erreur lors de la commande'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (cartProvider.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Votre panier est vide'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continuer les achats'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adresse de livraison',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (authProvider.user?.addresses != null &&
                          authProvider.user!.addresses!.length > 1)
                        TextButton(
                          onPressed: () async {
                            final result =
                                await showModalBottomSheet<AddressModel>(
                              context: context,
                              builder: (ctx) => _AddressSelector(
                                addresses: authProvider.user!.addresses!,
                                selectedAddress: _selectedAddress,
                              ),
                            );
                            if (result != null) {
                              setState(() => _selectedAddress = result);
                            }
                          },
                          child: const Text('Changer'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedAddress != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _selectedAddress!.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_selectedAddress!.fullAddress),
                          Text(
                              '${_selectedAddress!.quarter}, ${_selectedAddress!.city}'),
                          if (_selectedAddress!.details != null)
                            Text(
                              _selectedAddress!.details!,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.errorColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Aucune adresse enregistrée',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.push('/add-address'),
                            child: const Text('Ajouter une adresse'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Order Items
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Articles (${cartProvider.itemCount})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...cartProvider.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.product.name}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '${item.subtotal.toStringAsFixed(0)} ${AppConfig.currency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Payment Method
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode de paiement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.money, color: AppTheme.primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paiement à la livraison',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Payez en espèces à la réception',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: AppTheme.successColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Notes
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions de livraison (optionnel)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Appelez-moi 10 minutes avant d\'arriver',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sous-total'),
                  Text(
                    '${cartProvider.subtotal.toStringAsFixed(0)} ${AppConfig.currency}',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Livraison'),
                  Text(
                    '${cartProvider.deliveryFee.toStringAsFixed(0)} ${AppConfig.currency}',
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${cartProvider.total.toStringAsFixed(0)} ${AppConfig.currency}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Passer la commande',
                gradient: AppTheme.primaryGradient,
                icon: Icons.check_circle,
                isLoading: _isPlacingOrder,
                onPressed: _selectedAddress != null ? _placeOrder : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSelector extends StatelessWidget {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;

  const _AddressSelector({
    required this.addresses,
    this.selectedAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionner une adresse',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...addresses.map((address) => ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(address.label),
                subtitle: Text('${address.fullAddress}, ${address.city}'),
                trailing: selectedAddress?.id == address.id
                    ? const Icon(Icons.check_circle,
                        color: AppTheme.primaryColor)
                    : null,
                onTap: () => Navigator.pop(context, address),
              )),
        ],
      ),
    );
  }
}
