class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String role;
  final bool isActive;
  final bool isApproved;
  final String? avatar;
  final List<AddressModel>? addresses;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.role,
    this.isActive = true,
    this.isApproved = false,
    this.avatar,
    this.addresses,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'client',
      isActive: json['isActive'] ?? true,
      isApproved: json['isApproved'] ?? false,
      avatar: json['avatar'],
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
              .map((addr) => AddressModel.fromJson(addr))
              .toList()
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'isApproved': isApproved,
      'avatar': avatar,
      'addresses': addresses?.map((addr) => addr.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    bool? isApproved,
    String? avatar,
    List<AddressModel>? addresses,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      avatar: avatar ?? this.avatar,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AddressModel {
  final String? id;
  final String label;
  final String fullAddress;
  final String city;
  final String? quarter;
  final String? details;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    this.quarter,
    this.details,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'],
      label: json['label'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      city: json['city'] ?? '',
      quarter: json['quarter'],
      details: json['details'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'label': label,
      'fullAddress': fullAddress,
      'city': city,
      if (quarter != null) 'quarter': quarter,
      if (details != null) 'details': details,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? city,
    String? quarter,
    String? details,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      quarter: quarter ?? this.quarter,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
