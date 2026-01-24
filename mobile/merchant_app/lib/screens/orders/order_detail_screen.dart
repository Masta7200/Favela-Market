import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/custom_button.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    await context.read<OrderProvider>().getOrderById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text(order != null ? '#${order.orderNumber}' : 'Détails'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text('Commande non trouvée'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                )
              : _OrderDetailContent(order: order),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailContent({required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'picked':
        return Colors.indigo;
      case 'delivering':
        return Colors.deepPurple;
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.inventory_2;
      case 'picked':
        return Icons.local_shipping;
      case 'delivering':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(order.status),
                  _getStatusColor(order.status).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.createdAt != null
                            ? dateFormat.format(order.createdAt!)
                            : 'Date inconnue',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Order Progress
          _buildSectionTitle('Progression de la commande'),
          const SizedBox(height: 12),
          _OrderProgressStepper(currentStatus: order.status),
          const SizedBox(height: 24),

          // Items Section
          _buildSectionTitle('Articles commandés'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                ...order.items.map((item) => _OrderItemTile(item: item)),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPriceRow('Sous-total', order.subtotal),
                      const SizedBox(height: 8),
                      _buildPriceRow('Frais de livraison', order.deliveryFee),
                      const Divider(height: 20),
                      _buildPriceRow('Total', order.total, isTotal: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Delivery Address
          _buildSectionTitle('Adresse de livraison'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.deliveryAddress.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress.fullAddress,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      if (order.deliveryAddress.quarter != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryAddress.quarter!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      Text(
                        order.deliveryAddress.city,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment Method
          _buildSectionTitle('Mode de paiement'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiement à la livraison',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Le client paiera en espèces',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notes
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('Notes'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Text(
                order.notes!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Action Buttons
          _StatusUpdateButtons(order: order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppTheme.textPrimaryColor : Colors.grey[700],
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image,
                        size: 24,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Icon(
                    Icons.image,
                    size: 24,
                    color: Colors.grey[400],
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} FCFA x ${item.quantity}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.subtotal.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProgressStepper extends StatelessWidget {
  final String currentStatus;

  const _OrderProgressStepper({required this.currentStatus});

  List<Map<String, dynamic>> get _steps => [
        {'status': 'pending', 'label': 'En attente', 'icon': Icons.hourglass_empty},
        {'status': 'confirmed', 'label': 'Confirmée', 'icon': Icons.check_circle_outline},
        {'status': 'preparing', 'label': 'Préparation', 'icon': Icons.restaurant},
        {'status': 'ready', 'label': 'Prête', 'icon': Icons.inventory_2},
        {'status': 'delivering', 'label': 'Livraison', 'icon': Icons.delivery_dining},
        {'status': 'delivered', 'label': 'Livrée', 'icon': Icons.check_circle},
      ];

  int get _currentIndex {
    final index = _steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentStatus == 'picked') return 4;
    return index >= 0 ? index : 0;
  }

  bool _isCompleted(int index) => index <= _currentIndex;
  bool _isCurrent(int index) => index == _currentIndex;

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'cancelled' || currentStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Text(
              currentStatus == 'cancelled'
                  ? 'Cette commande a été annulée'
                  : 'Cette commande a été rejetée',
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: List.generate(_steps.length, (index) {
          final step = _steps[index];
          final isCompleted = _isCompleted(index);
          final isCurrent = _isCurrent(index);

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryColor
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(
                              color: AppTheme.primaryColor,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step['icon'] as IconData,
                      size: 16,
                      color: isCompleted ? Colors.white : Colors.grey[400],
                    ),
                  ),
                  if (index < _steps.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: isCompleted
                          ? AppTheme.primaryColor
                          : Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    step['label'] as String,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isCompleted
                          ? AppTheme.textPrimaryColor
                          : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusUpdateButtons extends StatelessWidget {
  final OrderModel order;

  const _StatusUpdateButtons({required this.order});

  String? get _nextStatus {
    switch (order.status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'preparing':
        return 'ready';
      case 'ready':
        return null; // Waiting for delivery pickup
      default:
        return null;
    }
  }

  String get _nextStatusLabel {
    switch (_nextStatus) {
      case 'confirmed':
        return 'Confirmer la commande';
      case 'preparing':
        return 'Commencer la préparation';
      case 'ready':
        return 'Marquer comme prête';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (order.status == 'delivered' ||
        order.status == 'cancelled' ||
        order.status == 'rejected') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_nextStatus != null)
          CustomButton(
            text: _nextStatusLabel,
            gradient: AppTheme.primaryGradient,
            icon: Icons.arrow_forward,
            onPressed: () => _updateStatus(context, _nextStatus!),
          ),
        if (order.status == 'pending') ...[
          const SizedBox(height: 12),
          CustomButton(
            text: 'Rejeter la commande',
            backgroundColor: AppTheme.errorColor,
            icon: Icons.cancel,
            onPressed: () => _showRejectDialog(context),
          ),
        ],
      ],
    );
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mettre à jour le statut'),
        content: Text('Changer le statut vers "${_getStatusLabel(newStatus)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.updateOrderStatus(order.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Statut mis à jour avec succès'
                  : orderProvider.error ?? 'Erreur lors de la mise à jour',
            ),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
        if (success) {
          orderProvider.getOrderById(order.id);
        }
      }
    }
  }

  void _showRejectDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la commande'),
        content: const Text(
          'Êtes-vous sûr de vouloir rejeter cette commande? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.updateOrderStatus(order.id, 'rejected');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Commande rejetée'
                  : orderProvider.error ?? 'Erreur lors du rejet',
            ),
            backgroundColor: success ? AppTheme.warningColor : AppTheme.errorColor,
          ),
        );
        if (success) {
          context.pop();
        }
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'picked':
        return 'Récupérée';
      case 'delivering':
        return 'En livraison';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      case 'rejected':
        return 'Rejetée';
      default:
        return status;
    }
  }
}
