class DeliveryUserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool isApproved;
  final bool isActive;
  final bool isAvailable;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? rejectionReason;
  final String? avatar;
  final DateTime? createdAt;

  DeliveryUserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.role = 'delivery',
    this.isApproved = false,
    this.isActive = true,
    this.isAvailable = false,
    this.vehicleType,
    this.vehicleNumber,
    this.rejectionReason,
    this.avatar,
    this.createdAt,
  });

  factory DeliveryUserModel.fromJson(Map<String, dynamic> json) {
    return DeliveryUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'delivery',
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
      isAvailable: json['isAvailable'] ?? false,
      vehicleType: json['vehicleType'],
      vehicleNumber: json['vehicleNumber'],
      rejectionReason: json['rejectionReason'],
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
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
      'isAvailable': isAvailable,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rejectionReason': rejectionReason,
      'avatar': avatar,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  DeliveryUserModel copyWith({bool? isAvailable}) {
    return DeliveryUserModel.fromJson({
      ...toJson(),
      if (isAvailable != null) 'isAvailable': isAvailable,
    });
  }

  String get statusText {
    if (!isActive) return 'Suspendu';
    if (!isApproved && rejectionReason != null) return 'Non validé';
    if (!isApproved) return 'En attente de vérification';
    return 'Vérifié';
  }

  String get vehicleTypeText => vehicleTypeLabel(vehicleType);

  bool get canDeliver => isApproved && isActive;

  // Values match the backend User.vehicleType enum
  static const Map<String, String> vehicleTypes = {
    'moto': 'Moto',
    'velo': 'Vélo',
    'voiture': 'Voiture',
  };

  static String vehicleTypeLabel(String? type) =>
      vehicleTypes[type] ?? 'Non défini';
}
