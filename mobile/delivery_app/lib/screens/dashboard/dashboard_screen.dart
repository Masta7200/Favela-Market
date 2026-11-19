import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/order_card.dart';
import '../deliveries/deliveries_screen.dart';
import '../products/products_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh as soon as the driver comes back to the app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<OrderProvider>().fetchOrders();
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  Future<void> _start() async {
    final orderProvider = context.read<OrderProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final productProvider = context.read<ProductProvider>();
    final authProvider = context.read<AuthProvider>();

    await NotificationService.requestPermission();
    notificationProvider.startPolling(
      onOrdersChanged: orderProvider.fetchOrders,
      // If the admin withdraws the approval, build() sends us back to the pending screen
      onAccountChanged: authProvider.refreshProfile,
    );

    // App was opened by tapping a notification
    final launchOrderId = NotificationService.launchOrderId;
    if (launchOrderId != null && mounted) {
      NotificationService.launchOrderId = null;
      context.push('/order/$launchOrderId');
    }

    await Future.wait([
      orderProvider.fetchOrders(),
      productProvider.fetchProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final newCount = context.watch<OrderProvider>().newAssignments.length;
    final user = context.watch<AuthProvider>().user;

    // Session ended (logout / expired token) or approval revoked by the admin
    if (user == null || !user.canDeliver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NotificationProvider>().stopPolling();
        context.go(user == null ? '/login' : '/pending-approval');
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onSeeAll: () => setState(() => _currentIndex = 1)),
          const DeliveriesScreen(embedded: true),
          const ProductsScreen(embedded: true),
          const ProfileScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: newCount > 0,
              label: Text('$newCount'),
              child: const Icon(Icons.delivery_dining_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: newCount > 0,
              label: Text('$newCount'),
              child: const Icon(Icons.delivery_dining),
            ),
            label: 'Livraisons',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produits',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _HomeTab({required this.onSeeAll});

  Future<void> _toggleAvailability(BuildContext context, bool value) async {
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await authProvider.setAvailability(value);
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Impossible de changer le statut'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final orderProvider = context.watch<OrderProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;
    final newOrders = orderProvider.newAssignments;
    final active = orderProvider.activeDeliveries;
    final isAvailable = user?.isAvailable ?? false;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user?.name ?? 'Livreur'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              user != null
                  ? '${user.vehicleTypeText}${user.vehicleNumber != null ? ' • ${user.vehicleNumber}' : ''}'
                  : '',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<AuthProvider>().refreshProfile(),
            context.read<OrderProvider>().fetchOrders(),
            context.read<NotificationProvider>().fetchNotifications(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isAvailable ? AppTheme.primaryGradient : null,
                  color: isAvailable ? null : Colors.grey[700],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable ? 'Disponible' : 'Hors ligne',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isAvailable
                                ? 'Vous pouvez recevoir de nouvelles livraisons'
                                : 'Activez pour recevoir des livraisons',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAvailable,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white38,
                      onChanged: (v) => _toggleAvailability(context, v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    title: 'Nouvelles',
                    value: '${newOrders.length}',
                    subtitle: 'à accepter',
                    icon: Icons.notifications_active,
                    gradient: AppTheme.secondaryGradient,
                  ),
                  _StatCard(
                    title: 'En cours',
                    value: '${active.length}',
                    subtitle: 'à livrer',
                    icon: Icons.delivery_dining,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Livrées aujourd\'hui',
                    value: '${orderProvider.deliveredToday.length}',
                    subtitle: '${orderProvider.deliveredOrders.length} au total',
                    icon: Icons.check_circle,
                    color: AppTheme.successColor,
                  ),
                  _StatCard(
                    title: 'Encaissé aujourd\'hui',
                    value: formatAmount(orderProvider.cashCollectedToday),
                    subtitle: orderProvider.cashToCollect > 0
                        ? '${formatAmount(orderProvider.cashToCollect)} à encaisser'
                        : null,
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (orderProvider.error != null && orderProvider.orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          orderProvider.error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),

              // New assignments
              _SectionTitle(
                title: 'Nouvelles affectations',
                count: newOrders.length,
                onSeeAll: newOrders.length > 3 ? onSeeAll : null,
              ),
              const SizedBox(height: 12),
              if (newOrders.isEmpty)
                const _EmptyHint(
                  icon: Icons.inbox_outlined,
                  text: 'Aucune nouvelle livraison pour le moment',
                )
              else
                ...newOrders.take(3).map((o) => OrderCard(order: o)),
              const SizedBox(height: 16),

              // Active deliveries
              _SectionTitle(
                title: 'Livraisons en cours',
                count: active.length,
                onSeeAll: active.length > 3 ? onSeeAll : null,
              ),
              const SizedBox(height: 12),
              if (active.isEmpty)
                const _EmptyHint(
                  icon: Icons.delivery_dining_outlined,
                  text: 'Aucune livraison en cours',
                )
              else
                ...active.take(3).map((o) => OrderCard(order: o)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onSeeAll;

  const _SectionTitle({required this.title, required this.count, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 11,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
        const Spacer(),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('Voir tout')),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final Gradient? gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final onGradient = gradient != null;
    final accent = color ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        color: onGradient ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: onGradient ? Colors.white70 : AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 22, color: onGradient ? Colors.white : accent),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: onGradient ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: onGradient ? Colors.white70 : AppTheme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
