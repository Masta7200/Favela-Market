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
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'],
      categoryId: json['categoryId'] ?? json['category']?['_id'] ?? '',
      categoryName: json['categoryName'] ?? json['category']?['name'] ?? '',
      merchantId: json['merchantId'] ?? json['merchant']?['_id'] ?? '',
      merchantName: json['merchantName'] ?? json['merchant']?['shopName'] ?? '',
      stock: json['stock'] ?? 0,
      status: json['status'] ?? 'approved',
      isApproved: json['isApproved'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
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
