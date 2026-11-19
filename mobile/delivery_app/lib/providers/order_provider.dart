import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  // Assigned by the admin, waiting for the delivery person to accept
  List<OrderModel> get newAssignments =>
      _orders.where((o) => o.isAwaitingAcceptance).toList();

  // Accepted and not yet delivered
  List<OrderModel> get activeDeliveries =>
      _orders.where((o) => o.isActiveDelivery).toList();

  List<OrderModel> get finishedDeliveries =>
      _orders.where((o) => o.isFinished).toList();

  List<OrderModel> get deliveredOrders => _orders
      .where((o) => o.status == 'delivered' || o.status == 'completed')
      .toList();

  List<OrderModel> get deliveredToday {
    final now = DateTime.now();
    return deliveredOrders.where((o) {
      final date = (o.deliveredAt ?? o.updatedAt)?.toLocal();
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  /// Cash currently carried for orders in progress.
  double get cashToCollect =>
      activeDeliveries.fold(0.0, (sum, o) => sum + o.amountToCollect);

  /// Cash collected today on delivered cash orders.
  double get cashCollectedToday =>
      deliveredToday.fold(0.0, (sum, o) => sum + o.amountToCollect);

  Future<void> fetchOrders() async {
    try {
      _isLoading = true;
      _error = null;
      Future.microtask(() => notifyListeners());

      final response = await ApiService.get(AppConfig.ordersEndpoint);

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> list = data is List
            ? data
            : (data is Map ? (data['orders'] ?? data['data'] ?? []) : []);

        _orders = list.map((json) => OrderModel.fromJson(json)).toList();
        _orders.sort((a, b) => (b.assignedAt ?? b.createdAt ?? DateTime.now())
            .compareTo(a.assignedAt ?? a.createdAt ?? DateTime.now()));
      }

      _isLoading = false;
      Future.microtask(() => notifyListeners());
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      Future.microtask(() => notifyListeners());

      final response = await ApiService.get(AppConfig.orderEndpoint(orderId));

      if (response['success'] == true) {
        // Backend wraps the order: { data: { order: {...} } }
        _currentOrder = OrderModel.fromJson(_extractOrder(response['data']));
        _replaceInList(_currentOrder!);
      }

      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return _currentOrder;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return null;
    }
  }

  Future<bool> acceptOrder(String orderId) {
    return _updateOrder(
      () => ApiService.put(AppConfig.acceptOrderEndpoint(orderId), {}),
      orderId,
    );
  }

  Future<bool> declineOrder(String orderId, {String? reason}) async {
    final success = await _updateOrder(
      () => ApiService.put(
        AppConfig.declineOrderEndpoint(orderId),
        {if (reason != null && reason.isNotEmpty) 'reason': reason},
      ),
      orderId,
      // The order is no longer ours: reloading it would return 403
      reload: false,
    );
    if (success) {
      // A declined order is no longer assigned to us
      _orders.removeWhere((o) => o.id == orderId);
      if (_currentOrder?.id == orderId) _currentOrder = null;
      notifyListeners();
    }
    return success;
  }

  Future<bool> markPickedUp(String orderId) {
    return _updateOrder(
      () => ApiService.put(
        AppConfig.deliveryStatusEndpoint(orderId),
        {'status': 'in_transit'},
      ),
      orderId,
    );
  }

  Future<bool> markDelivered(String orderId) {
    return _updateOrder(
      () => ApiService.put(
        AppConfig.deliveryStatusEndpoint(orderId),
        {'status': 'delivered'},
      ),
      orderId,
    );
  }

  Future<bool> _updateOrder(
    Future<Map<String, dynamic>> Function() request,
    String orderId, {
    bool reload = true,
  }) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();

      final response = await request();

      if (response['success'] == true) {
        final orderJson = _extractOrder(response['data']);
        if (orderJson is Map<String, dynamic> && orderJson['_id'] != null) {
          final updated = OrderModel.fromJson(orderJson);
          _replaceInList(updated);
          if (_currentOrder?.id == orderId) _currentOrder = updated;
        }
        // The update response may not be fully populated; reload the detail
        if (reload && _currentOrder?.id == orderId) await getOrderById(orderId);

        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la mise à jour';
      _isUpdating = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  dynamic _extractOrder(dynamic data) =>
      (data is Map && data['order'] != null) ? data['order'] : data;

  void _replaceInList(OrderModel order) {
    final idx = _orders.indexWhere((o) => o.id == order.id);
    if (idx != -1) _orders[idx] = order;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _orders = [];
    _currentOrder = null;
    _error = null;
    notifyListeners();
  }
}
