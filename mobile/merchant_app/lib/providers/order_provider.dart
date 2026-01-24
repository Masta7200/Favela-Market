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

  // Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Fetch merchant's orders
  Future<void> fetchOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.get(AppConfig.ordersEndpoint);

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['orders'] ?? [];
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();

        // Sort by date (newest first)
        _orders.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
      }

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.get(
        '${AppConfig.ordersEndpoint}/$orderId',
      );

      if (response['success'] == true) {
        _currentOrder = OrderModel.fromJson(response['data']['order']);
        _isLoading = false;
        notifyListeners();
        return _currentOrder;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.put(
        '${AppConfig.ordersEndpoint}/$orderId/status',
        {'status': newStatus},
      );

      if (response['success'] == true) {
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
