import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/usermodel.dart';
import '../services/apiservices.dart';
import '../config/app_config.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch user orders
  Future<void> fetchOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(AppConfig.ordersEndpoint);

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
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.get(
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

  // Create order
  Future<OrderModel?> createOrder({
    required List<OrderItemModel> items,
    required AddressModel deliveryAddress,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post(
        AppConfig.ordersEndpoint,
        {
          'items': items.map((item) => item.toJson()).toList(),
          'deliveryAddress': deliveryAddress.toJson(),
          'paymentMethod': 'cod',
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response['success'] == true) {
        final order = OrderModel.fromJson(response['data']['order']);
        _orders.insert(0, order); // Add to beginning
        _isLoading = false;
        notifyListeners();
        return order;
      }

      _error =
          response['message'] ?? 'Erreur lors de la création de la commande';
      _isLoading = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.put(
        '${AppConfig.ordersEndpoint}/$orderId/cancel',
        {},
      );

      if (response['success'] == true) {
        // Update local order status
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index >= 0) {
          await fetchOrders(); // Refresh orders
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de l\'annulation';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}
