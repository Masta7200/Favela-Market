import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/storageservices.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  int get uniqueItemCount => _items.length;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get deliveryFee => 1000.0; // Fixed delivery fee for MVP

  double get total => subtotal + deliveryFee;

  Future<void> loadCart() async {
    try {
      final cartData = StorageService.getCart();
      _items = cartData.map((item) => CartItemModel.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      _items = [];
    }
  }

  // Save cart to storage
  Future<void> _saveCart() async {
    try {
      final cartData = _items.map((item) => item.toJson()).toList();
      await StorageService.saveCart(cartData);
    } catch (e) {
      // Silently fail
    }
  }

  // Add item to cart
  void addItem(ProductModel product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(product: product, quantity: quantity));
    }

    _saveCart();
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  // Increase quantity
  void increaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        _saveCart();
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Get item quantity
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItemModel(
          product: ProductModel(
            id: '',
            name: '',
            description: '',
            price: 0,
            categoryId: '',
            categoryName: '',
            merchantId: '',
            merchantName: '',
            stock: 0,
          ),
          quantity: 0),
    );
    return item.quantity;
  }

  // Clear cart
  Future<void> clearCart() async {
    _items = [];
    await StorageService.clearCart();
    notifyListeners();
  }
}
