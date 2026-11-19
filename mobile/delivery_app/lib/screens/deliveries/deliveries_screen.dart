import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_card.dart';

class DeliveriesScreen extends StatefulWidget {
  /// True when shown as a tab of the dashboard (no back button).
  final bool embedded;

  const DeliveriesScreen({super.key, this.embedded = false});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() => context.read<OrderProvider>().fetchOrders();

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final newOrders = orderProvider.newAssignments;
    final active = orderProvider.activeDeliveries;
    final finished = orderProvider.finishedDeliveries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Nouvelles (${newOrders.length})'),
            Tab(text: 'En cours (${active.length})'),
            Tab(text: 'Terminées (${finished.length})'),
          ],
        ),
      ),
      body: orderProvider.isLoading && orderProvider.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OrdersList(
                  orders: newOrders,
                  onRefresh: _loadOrders,
                  error: orderProvider.error,
                  emptyIcon: Icons.notifications_none,
                  emptyMessage: 'Aucune nouvelle livraison',
                  emptyHint:
                      'Vous serez notifié dès qu\'une commande vous est attribuée.',
                ),
                _OrdersList(
                  orders: active,
                  onRefresh: _loadOrders,
                  error: orderProvider.error,
                  emptyIcon: Icons.delivery_dining,
                  emptyMessage: 'Aucune livraison en cours',
                ),
                _OrdersList(
                  orders: finished,
                  onRefresh: _loadOrders,
                  error: orderProvider.error,
                  emptyIcon: Icons.history,
                  emptyMessage: 'Aucune livraison terminée',
                ),
              ],
            ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  final Future<void> Function() onRefresh;
  final String? error;
  final IconData emptyIcon;
  final String emptyMessage;
  final String? emptyHint;

  const _OrdersList({
    required this.orders,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyMessage,
    this.error,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Icon(
                  error != null ? Icons.cloud_off : emptyIcon,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  error != null ? 'Impossible de charger les livraisons' : emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error != null || emptyHint != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error ?? emptyHint!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) => OrderCard(order: orders[index]),
            ),
    );
  }
}
