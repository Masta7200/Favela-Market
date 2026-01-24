class MerchantModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool isApproved;
  final bool isActive;
  final String? shopName;
  final String? shopDescription;
  final String? shopLogo;
  final String? shopBanner;
  final DateTime? createdAt;

  MerchantModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.role = 'merchant',
    this.isApproved = false,
    this.isActive = true,
    this.shopName,
    this.shopDescription,
    this.shopLogo,
    this.shopBanner,
    this.createdAt,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'merchant',
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
      shopName: json['shopName'],
      shopDescription: json['shopDescription'],
      shopLogo: json['shopLogo'],
      shopBanner: json['shopBanner'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'isActive': isActive,
      'shopName': shopName,
      'shopDescription': shopDescription,
      'shopLogo': shopLogo,
      'shopBanner': shopBanner,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get statusText {
    if (!isActive) return 'Suspendu';
    if (!isApproved) return 'En attente d\'approbation';
    return 'Actif';
  }

  bool get canSell => isApproved && isActive;
}
