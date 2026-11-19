import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../utils/launcher.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/order_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
  }

  Future<void> _loadOrder() async {
    await context.read<OrderProvider>().getOrderById(widget.orderId);
    if (mounted) setState(() => _loaded = true);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _markPickedUp(OrderModel order) async {
    final confirm = await _confirm(
      title: 'Commande récupérée?',
      message:
          'Confirmez que vous avez récupéré la commande ${order.orderNumber} chez ${order.merchant?.name ?? 'le vendeur'}. Le client sera informé que sa commande est en route.',
      action: 'Confirmer',
    );
    if (confirm != true || !mounted) return;

    final provider = context.read<OrderProvider>();
    final success = await provider.markPickedUp(order.id);
    _showResult(success, 'Commande en route vers le client', provider.error);
  }

  Future<void> _markDelivered(OrderModel order) async {
    final collect = order.amountToCollect;
    final confirm = await _confirm(
      title: 'Confirmer la livraison',
      message: collect > 0
          ? 'Confirmez que la commande a été remise au client et que vous avez encaissé ${formatAmount(collect)}.'
          : 'Confirmez que la commande a été remise au client.',
      action: 'Livrée',
    );
    if (confirm != true || !mounted) return;

    final provider = context.read<OrderProvider>();
    final success = await provider.markDelivered(order.id);
    _showResult(success, 'Livraison terminée. Merci!', provider.error);
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _showResult(bool success, String successMessage, String? error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : error ?? 'Erreur de mise à jour'),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = provider.currentOrder?.id == widget.orderId
        ? provider.currentOrder
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(order?.orderNumber ?? 'Détails de la livraison'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _close,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: order == null
          ? (!_loaded || provider.isLoading)
              ? const Center(child: CircularProgressIndicator())
              : _buildError(provider.error)
          : RefreshIndicator(
              onRefresh: _loadOrder,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(order),
                  const SizedBox(height: 16),
                  _buildProgress(order),
                  const SizedBox(height: 16),
                  _buildPickupCard(order),
                  const SizedBox(height: 16),
                  _buildCustomerCard(order),
                  const SizedBox(height: 16),
                  _buildItemsCard(order),
                  const SizedBox(height: 16),
                  _buildPaymentCard(order),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Instructions',
                      icon: Icons.sticky_note_2_outlined,
                      children: [Text(order.notes!)],
                    ),
                  ],
                  if (order.status == 'cancelled' &&
                      order.cancelReason != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Commande annulée',
                      icon: Icons.cancel_outlined,
                      children: [Text(order.cancelReason!)],
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: order == null ? null : _buildActionBar(order, provider),
    );
  }

  Widget _buildError(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              error ?? 'Commande introuvable',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrder,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildActionBar(OrderModel order, OrderProvider provider) {
    Widget? child;
    if (order.isAwaitingAcceptance) {
      child = AssignmentActions(order: order, onDeclined: _close);
    } else if (order.canPickUp) {
      child = CustomButton(
        text: 'J\'ai récupéré la commande',
        icon: Icons.inventory_2,
        gradient: AppTheme.secondaryGradient,
        backgroundColor: AppTheme.secondaryColor,
        isLoading: provider.isUpdating,
        onPressed: () => _markPickedUp(order),
      );
    } else if (order.canMarkDelivered) {
      child = CustomButton(
        text: 'Confirmer la livraison',
        icon: Icons.check_circle,
        gradient: AppTheme.primaryGradient,
        isLoading: provider.isUpdating,
        onPressed: () => _markDelivered(order),
      );
    }
    if (child == null) return null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.assignedAt != null
                      ? 'Attribuée le ${formatDateTime(order.assignedAt)}'
                      : 'Commandée le ${formatDateTime(order.createdAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.statusText,
              style: TextStyle(
                color: orderStatusColor(order),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(OrderModel order) {
    final accepted = order.deliveryAcceptedAt != null;
    final pickedUp = order.status == 'in_transit' ||
        order.status == 'delivered' ||
        order.status == 'completed';
    final delivered =
        order.status == 'delivered' || order.status == 'completed';

    final steps = [
      ('Acceptée', accepted, order.deliveryAcceptedAt),
      ('Récupérée', pickedUp, order.pickedUpAt),
      ('Livrée', delivered, order.deliveredAt),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: steps[i].$2
                        ? AppTheme.successColor
                        : Colors.grey[300],
                    child: Icon(
                      steps[i].$2 ? Icons.check : Icons.circle,
                      size: steps[i].$2 ? 18 : 8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          steps[i].$2 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (steps[i].$3 != null)
                    Text(
                      formatDateTime(steps[i].$3),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickupCard(OrderModel order) {
    final merchant = order.merchant;
    return _buildCard(
      title: 'Point de retrait',
      icon: Icons.storefront,
      children: [
        Text(
          merchant?.name.isNotEmpty == true ? merchant!.name : 'Vendeur',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        if (merchant?.address != null && merchant!.address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(merchant.address!,
              style: const TextStyle(color: AppTheme.textSecondaryColor)),
        ],
        if (merchant?.phone != null || merchant?.address != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (merchant?.phone != null)
                _ActionChip(
                  icon: Icons.call,
                  label: 'Appeler',
                  onTap: () => callPhone(context, merchant!.phone!),
                ),
              if (merchant?.address != null &&
                  merchant!.address!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.map,
                  label: 'Itinéraire',
                  onTap: () => openMaps(context, merchant.address!),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
    final phone = order.customerPhone;
    final address = order.deliveryAddress;
    return _buildCard(
      title: 'Livrer à',
      icon: Icons.person_pin_circle,
      children: [
        Text(
          order.client?.name ?? 'Client',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        if (phone != null) ...[
          const SizedBox(height: 2),
          Text(phone, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on,
                size: 18, color: AppTheme.secondaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(order.addressText.isEmpty
                  ? 'Adresse non précisée'
                  : order.addressText),
            ),
          ],
        ),
        if (address.details != null && address.details!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            address.details!,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (phone != null) ...[
              _ActionChip(
                icon: Icons.call,
                label: 'Appeler',
                onTap: () => callPhone(context, phone),
              ),
              _ActionChip(
                icon: Icons.sms,
                label: 'SMS',
                onTap: () => sendSms(context, phone),
              ),
            ],
            if (order.addressText.isNotEmpty)
              _ActionChip(
                icon: Icons.map,
                label: 'Itinéraire',
                onTap: () => openMaps(context, order.addressText),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return _buildCard(
      title: 'Articles (${order.itemCount})',
      icon: Icons.shopping_bag_outlined,
      children: [
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: item.productImage != null
                        ? CachedNetworkImage(
                            imageUrl: item.productImage!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Icon(Icons.image, color: Colors.grey[400]),
                          )
                        : Icon(Icons.image, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.quantity} × ${formatAmount(item.price)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatAmount(item.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    final collect = order.amountToCollect;
    return _buildCard(
      title: 'Paiement',
      icon: Icons.payments_outlined,
      children: [
        _row('Sous-total', formatAmount(order.subtotal)),
        if (order.deliveryFee > 0)
          _row('Frais de livraison', formatAmount(order.deliveryFee)),
        const Divider(height: 20),
        _row('Total', formatAmount(order.total), bold: true),
        const SizedBox(height: 8),
        _row('Mode', order.paymentMethodText),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (collect > 0 ? AppTheme.secondaryColor : AppTheme.successColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                collect > 0 ? Icons.account_balance_wallet : Icons.verified,
                color: collect > 0
                    ? AppTheme.secondaryColor
                    : AppTheme.successColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  collect > 0
                      ? 'À encaisser auprès du client: ${formatAmount(collect)}'
                      : 'Déjà payée — rien à encaisser',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: collect > 0
                        ? AppTheme.secondaryColor
                        : AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
      color: bold ? AppTheme.primaryColor : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: bold ? style : const TextStyle(
            color: AppTheme.textSecondaryColor,
          )),
          const Spacer(),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
