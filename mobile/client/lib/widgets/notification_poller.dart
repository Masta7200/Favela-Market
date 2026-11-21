import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';

/// Placed at the root of the app: checks for notifications while the client
/// is logged in, stops on logout, and checks again when the app comes back
/// to the foreground (so banners missed in the background still show).
class NotificationPoller extends StatefulWidget {
  final Widget child;

  const NotificationPoller({super.key, required this.child});

  @override
  State<NotificationPoller> createState() => _NotificationPollerState();
}

class _NotificationPollerState extends State<NotificationPoller>
    with WidgetsBindingObserver {
  bool? _wasAuthenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    if (isAuthenticated == _wasAuthenticated) return;
    _wasAuthenticated = isAuthenticated;

    final notifications = context.read<NotificationProvider>();
    if (isAuthenticated) {
      final orders = context.read<OrderProvider>();
      // After the current frame: providers must not notify during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifications.startPolling(onOrdersChanged: orders.fetchOrders);
      });
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => notifications.clear());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wasAuthenticated == true) {
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
