class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.image,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      image: json['image'],
      productCount: json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'image': image,
      'productCount': productCount,
    };
  }
}
