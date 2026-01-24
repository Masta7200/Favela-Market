import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch merchant's products
  Future<void> fetchProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.get(AppConfig.productsEndpoint);

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['products'] ?? [];
        _products = data.map((json) => ProductModel.fromJson(json)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      final response = await ApiService.get('/categories', includeAuth: false);

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['categories'] ?? [];
        _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for categories
    }
  }

  // Add product
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required int stock,
    String? image,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.post(
        AppConfig.productsEndpoint,
        {
          'name': name,
          'description': description,
          'price': price,
          'categoryId': categoryId,
          'stock': stock,
          if (image != null) 'image': image,
        },
      );

      if (response['success'] == true) {
        await fetchProducts();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de l\'ajout du produit';
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

  // Update product
  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required int stock,
    String? image,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.put(
        '${AppConfig.productsEndpoint}/$productId',
        {
          'name': name,
          'description': description,
          'price': price,
          'categoryId': categoryId,
          'stock': stock,
          if (image != null) 'image': image,
        },
      );

      if (response['success'] == true) {
        await fetchProducts();
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

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.delete(
        '${AppConfig.productsEndpoint}/$productId',
      );

      if (response['success'] == true) {
        _products.removeWhere((p) => p.id == productId);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Erreur lors de la suppression';
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

  // Get product by ID
  ProductModel? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
