import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

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
        _orders.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
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
      Future.microtask(() => notifyListeners());

      final response = await ApiService.get(AppConfig.orderEndpoint(orderId));

      if (response['success'] == true) {
        // Backend wraps the order: { data: { order: {...} } }
        final data = response['data'];
        final orderJson = (data is Map && data['order'] != null)
            ? data['order']
            : data;
        _currentOrder = OrderModel.fromJson(orderJson);
        _isLoading = false;
        Future.microtask(() => notifyListeners());
        return _currentOrder;
      }

      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return null;
    } catch (e) {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.put(
        AppConfig.orderStatusEndpoint(orderId),
        {'status': newStatus},
      );

      if (response['success'] == true) {
        // Parse updated order from response and apply immediately
        final data = response['data'];
        final orderJson = (data is Map && data['order'] != null)
            ? data['order']
            : data;
        if (orderJson != null) {
          final updated = OrderModel.fromJson(orderJson);
          // Update in the list
          final idx = _orders.indexWhere((o) => o.id == orderId);
          if (idx != -1) _orders[idx] = updated;
          // Update current order if it's the same one
          if (_currentOrder?.id == orderId) _currentOrder = updated;
        }

        await fetchOrders();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la mise à jour';
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}
