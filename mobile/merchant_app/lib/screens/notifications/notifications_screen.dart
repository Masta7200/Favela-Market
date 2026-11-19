import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(showLoading: true);
    });
  }

  void _open(NotificationModel n) {
    context.read<NotificationProvider>().markAsRead(n.id);
    if (n.orderId != null) {
      context.push('/order/${n.orderId}');
    } else if (n.isProductUpdate) {
      context.push('/products');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM, HH:mm', 'fr_FR').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: provider.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchNotifications(),
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2),
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune notification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les nouvelles commandes apparaîtront ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return ListTile(
                          tileColor: n.isRead
                              ? null
                              : AppTheme.primaryColor.withOpacity(0.05),
                          leading: CircleAvatar(
                            backgroundColor: n.color.withOpacity(0.12),
                            child: Icon(n.icon, color: n.color),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(n.message),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(n.createdAt),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: n.isRead
                              ? null
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () => _open(n),
                        );
                      },
                    ),
            ),
    );
  }
}
