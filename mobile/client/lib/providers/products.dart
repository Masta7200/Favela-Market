import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/apiservices.dart';
import '../config/app_config.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all products
  Future<void> fetchProducts({String? categoryId, String? search}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String endpoint = AppConfig.productsEndpoint;

      // Add query parameters
      List<String> params = [];
      if (categoryId != null && categoryId.isNotEmpty) {
        params.add('categoryId=$categoryId');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiService.get(endpoint, includeAuth: false);

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
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      final response = await _apiService.get(
        AppConfig.categoriesEndpoint,
        includeAuth: false,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['categories'] ?? [];
        _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Silently fail for categories
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await _apiService.get(
        '${AppConfig.productsEndpoint}/$productId',
        includeAuth: false,
      );

      if (response['success'] == true) {
        return ProductModel.fromJson(response['data']['product']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    await fetchProducts(search: query);
  }

  // Get products by category
  Future<void> getProductsByCategory(String categoryId) async {
    await fetchProducts(categoryId: categoryId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
