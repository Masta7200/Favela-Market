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
  bool _isLoadingMore = false;
  String? _error;

  // Current query, so "load more" fetches the next page of the same list
  String? _categoryId;
  String? _search;
  int _page = 1;
  int _pages = 1;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _page < _pages;
  String? get error => _error;

  String _endpoint(int page) {
    final params = <String, String>{
      'page': '$page',
      'limit': '${AppConfig.pageSize}',
      // The backend filters on "category"
      if (_categoryId != null && _categoryId!.isNotEmpty)
        'category': _categoryId!,
      if (_search != null && _search!.isNotEmpty) 'search': _search!,
    };
    return Uri.parse(AppConfig.productsEndpoint)
        .replace(queryParameters: params)
        .toString();
  }

  void _readPagination(Map<String, dynamic> response) {
    final pagination = response['data']?['pagination'];
    _pages = pagination is Map ? (pagination['pages'] as num? ?? 1).toInt() : 1;
  }

  // Fetch the first page of products (all, one category, or a search)
  Future<void> fetchProducts({String? categoryId, String? search}) async {
    try {
      _categoryId = categoryId;
      _search = search;
      _page = 1;
      _pages = 1;
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(_endpoint(1), includeAuth: false);

      if (response['success'] == true) {
        final List<dynamic> data = response['data']['products'] ?? [];
        _products = data.map((json) => ProductModel.fromJson(json)).toList();
        _readPagination(response);
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

  // Append the next page of the current list
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    try {
      _isLoadingMore = true;
      notifyListeners();

      final response =
          await _apiService.get(_endpoint(_page + 1), includeAuth: false);
      if (response['success'] == true) {
        final List<dynamic> data = response['data']['products'] ?? [];
        final ids = _products.map((p) => p.id).toSet();
        _products.addAll(data
            .map((json) => ProductModel.fromJson(json))
            .where((p) => !ids.contains(p.id)));
        _page += 1;
        _readPagination(response);
      }
    } catch (_) {
      // Keep what is already displayed; the button stays to retry
    } finally {
      _isLoadingMore = false;
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
