import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.getOrderById(widget.orderId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette commande?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.cancelOrder(widget.orderId);

    if (!mounted) return;

    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande annulée'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _loadOrder(); // Reload order
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Erreur lors de l\'annulation'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
      case 'rejected':
        return AppTheme.errorColor;
      case 'delivering':
      case 'picked':
        return AppTheme.warningColor;
      case 'confirmed':
      case 'preparing':
      case 'ready':
        return Colors.blue;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  bool _canCancelOrder(String status) {
    return status == 'pending' || status == 'confirmed';
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de la commande')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de la commande')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Commande non trouvée'),
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

    final statusColor = _getStatusColor(order.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la commande'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status
            Container(
              padding: const EdgeInsets.all(16),
              color: statusColor.withOpacity(0.1),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(order.status),
                    size: 60,
                    color: statusColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.statusText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commande #${order.orderNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (order.createdAt != null)
                    Text(
                      DateFormat('dd MMM yyyy à HH:mm', 'fr_FR')
                          .format(order.createdAt!),
                      style:
                          const TextStyle(color: AppTheme.textSecondaryColor),
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
                    'Articles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.productImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item.productImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.shopping_bag,
                                      color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.price.toStringAsFixed(0)} ${AppConfig.currency} x ${item.quantity}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.subtotal.toStringAsFixed(0)} ${AppConfig.currency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Delivery Address
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adresse de livraison',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryAddress.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(order.deliveryAddress.fullAddress),
                            Text(
                              '${order.deliveryAddress.quarter}, ${order.deliveryAddress.city}',
                            ),
                            if (order.deliveryAddress.details != null)
                              Text(
                                order.deliveryAddress.details!,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Payment Method & Notes
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mode de paiement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Paiement à la livraison (COD)'),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order.notes!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sous-total'),
                      Text(
                        '${order.subtotal.toStringAsFixed(0)} ${AppConfig.currency}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Livraison'),
                      Text(
                        '${order.deliveryFee.toStringAsFixed(0)} ${AppConfig.currency}',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${order.total.toStringAsFixed(0)} ${AppConfig.currency}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _canCancelOrder(order.status)
          ? Container(
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
                child: CustomButton(
                  text: 'Annuler la commande',
                  backgroundColor: AppTheme.errorColor,
                  isLoading: _isCancelling,
                  onPressed: _cancelOrder,
                ),
              ),
            )
          : null,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      case 'delivering':
        return Icons.local_shipping;
      case 'picked':
        return Icons.inventory;
      case 'ready':
        return Icons.done_all;
      case 'preparing':
        return Icons.restaurant;
      case 'confirmed':
        return Icons.check;
      default:
        return Icons.hourglass_empty;
    }
  }
}
