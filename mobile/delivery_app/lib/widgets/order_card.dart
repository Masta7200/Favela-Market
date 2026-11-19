import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

Color orderStatusColor(OrderModel order) {
  if (order.isAwaitingAcceptance) return AppTheme.secondaryColor;
  switch (order.status) {
    case 'ready':
      return Colors.purple;
    case 'in_transit':
      return Colors.blue;
    case 'delivered':
    case 'completed':
      return AppTheme.successColor;
    case 'cancelled':
    case 'rejected':
      return AppTheme.errorColor;
    default:
      return AppTheme.warningColor;
  }
}

String formatAmount(double amount) =>
    '${NumberFormat('#,###', 'fr_FR').format(amount)} FCFA';

String formatDateTime(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd MMM, HH:mm', 'fr_FR').format(date.toLocal());
}

class StatusBadge extends StatelessWidget {
  final OrderModel order;

  const StatusBadge({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
          border: order.isAwaitingAcceptance
              ? Border.all(color: AppTheme.secondaryColor.withOpacity(0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusBadge(order: order),
              ],
            ),
            const SizedBox(height: 12),
            if (order.merchant != null)
              _InfoLine(
                icon: Icons.storefront,
                text: 'Récupérer chez ${order.merchant!.name}',
              ),
            _InfoLine(
              icon: Icons.location_on,
              text: order.addressText.isEmpty
                  ? 'Adresse non précisée'
                  : order.addressText,
            ),
            if (order.client != null)
              _InfoLine(icon: Icons.person, text: order.client!.name),
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  '${order.itemCount} article(s)',
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const Spacer(),
                if (order.amountToCollect > 0) ...[
                  const Icon(Icons.payments_outlined,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  formatAmount(order.total),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (order.isAwaitingAcceptance) ...[
              const SizedBox(height: 12),
              AssignmentActions(order: order),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accept / decline buttons for an order newly assigned by the admin.
class AssignmentActions extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onDeclined;

  const AssignmentActions({super.key, required this.order, this.onDeclined});

  @override
  Widget build(BuildContext context) {
    final isUpdating = context.watch<OrderProvider>().isUpdating;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isUpdating ? null : () => _decline(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isUpdating ? null : () => _accept(context),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _accept(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.acceptOrder(order.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Livraison ${order.orderNumber} acceptée'
            : provider.error ?? 'Erreur lors de l\'acceptation'),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _decline(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('La commande ${order.orderNumber} sera réattribuée à un autre livreur.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                hintText: 'Ex: Trop loin, indisponible...',
              ),
            ),
          ],
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
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirm != true || !context.mounted) return;

    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.declineOrder(order.id, reason: reason);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Livraison refusée'
            : provider.error ?? 'Erreur lors du refus'),
        backgroundColor: success ? AppTheme.warningColor : AppTheme.errorColor,
      ),
    );
    if (success) onDeclined?.call();
  }
}
