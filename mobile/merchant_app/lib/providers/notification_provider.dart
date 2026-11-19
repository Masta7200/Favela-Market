import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/routes.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/in_app_notification.dart';

/// Keeps the notification list in sync with the backend while the app is
/// open, and shows each new one (new order, cancelled order, product or
/// account approval) as a banner at the top of the app.
class NotificationProvider extends ChangeNotifier {
  /// Older notifications are only listed, never popped up (e.g. after login)
  static const _alertMaxAge = Duration(minutes: 15);
  static const _maxBannersAtOnce = 3;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  bool _isFetching = false;
  VoidCallback? _onOrdersChanged;
  VoidCallback? _onProductsChanged;
  VoidCallback? _onAccountChanged;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Starts polling. The callbacks refresh the related data when a
  /// notification concerns orders, products or the merchant account.
  void startPolling({
    VoidCallback? onOrdersChanged,
    VoidCallback? onProductsChanged,
    VoidCallback? onAccountChanged,
  }) {
    _onOrdersChanged = onOrdersChanged;
    _onProductsChanged = onProductsChanged;
    _onAccountChanged = onAccountChanged;
    _timer?.cancel();
    fetchNotifications();
    _timer = Timer.periodic(
      AppConfig.notificationPollInterval,
      (_) => fetchNotifications(),
    );
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchNotifications({bool showLoading = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      if (showLoading) {
        _isLoading = true;
        Future.microtask(() => notifyListeners());
      }

      final response = await ApiService.get(AppConfig.notificationsEndpoint);

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> list = data is List
            ? data
            : (data is Map ? (data['notifications'] ?? []) : []);

        _notifications =
            list.map((json) => NotificationModel.fromJson(json)).toList();
        _notifications.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        _error = null;

        await _alertNewNotifications();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isFetching = false;
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> _alertNewNotifications() async {
    // In the background the banner can't be seen: keep them for when the
    // merchant comes back to the app
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final shown = StorageService.getShownNotificationIds();
    final fresh =
        _notifications.where((n) => !n.isRead && !shown.contains(n.id)).toList();
    if (fresh.isEmpty) return;

    final now = DateTime.now();
    final toAlert = fresh
        .where((n) =>
            n.createdAt == null ||
            now.difference(n.createdAt!.toLocal()) < _alertMaxAge)
        .toList()
        .reversed // oldest first
        .toList();

    for (final n in toAlert.take(_maxBannersAtOnce)) {
      InAppNotificationHost.show(
        title: n.title,
        message: n.message,
        icon: n.icon,
        color: n.color,
        onTap: () => _openFromBanner(n),
      );
    }
    if (toAlert.length > _maxBannersAtOnce) {
      InAppNotificationHost.show(
        title: '${toAlert.length - _maxBannersAtOnce} autres notifications',
        message: 'Appuyez pour tout voir',
        onTap: () => AppRouter.router.push('/notifications'),
      );
    }

    shown.addAll(fresh.map((n) => n.id));
    await StorageService.saveShownNotificationIds(shown);

    if (fresh.any((n) => n.orderId != null)) _onOrdersChanged?.call();
    if (fresh.any((n) => n.isProductUpdate)) _onProductsChanged?.call();
    if (fresh.any((n) => n.isAccountUpdate)) _onAccountChanged?.call();
  }

  void _openFromBanner(NotificationModel n) {
    markAsRead(n.id);
    if (n.orderId != null) {
      AppRouter.router.push('/order/${n.orderId}');
    } else if (n.isProductUpdate) {
      AppRouter.router.push('/products');
    } else {
      AppRouter.router.push('/notifications');
    }
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;

    _notifications[idx] = _notifications[idx].markRead();
    notifyListeners();

    try {
      await ApiService.put(AppConfig.notificationReadEndpoint(id), {});
    } on ApiException catch (_) {
      // Non critical: it will be re-synced on the next fetch
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    _notifications = _notifications.map((n) => n.markRead()).toList();
    notifyListeners();

    try {
      await ApiService.put(AppConfig.notificationsReadAllEndpoint, {});
    } on ApiException catch (_) {
      // Non critical: it will be re-synced on the next fetch
    }
  }

  void clear() {
    stopPolling();
    _notifications = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
