class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final String categoryId;
  final String categoryName;
  final String merchantId;
  final String merchantName;
  final int stock;
  final String status;
  final bool isApproved;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.categoryId,
    required this.categoryName,
    required this.merchantId,
    required this.merchantName,
    required this.stock,
    this.status = 'approved',
    this.isApproved = true,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] is String
          ? double.tryParse(json['price']) ?? 0.0
          : (json['price'] is num ? (json['price'] as num).toDouble() : 0.0),
      image: json['image'],
      categoryId: _extractId(json['categoryId'], json['category']),
      categoryName: _extractName(json['categoryName'], json['category']),
      merchantId: _extractId(json['merchantId'], json['merchant']),
      merchantName: _extractName(json['merchantName'], json['merchant']),
      stock: (json['stock'] is String)
          ? int.tryParse(json['stock']) ?? 0
          : (json['stock'] is int ? json['stock'] as int : 0),
      status: json['status'] ?? 'approved',
      isApproved: json['isApproved'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  static String _extractId(dynamic explicitId, dynamic nestedObject) {
    if (explicitId is String) return explicitId;
    if (nestedObject is String) return nestedObject;
    if (nestedObject is Map && nestedObject['_id'] != null) {
      return nestedObject['_id'].toString();
    }
    return '';
  }

  static String _extractName(dynamic explicitName, dynamic nestedObject) {
    if (explicitName is String) return explicitName;
    if (nestedObject is Map && nestedObject['name'] is String) {
      return nestedObject['name'];
    }
    if (nestedObject is Map && nestedObject['shopName'] is String) {
      return nestedObject['shopName'];
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'stock': stock,
      'status': status,
      'isApproved': isApproved,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isAvailable => stock > 0 && isApproved && status == 'approved';
}
