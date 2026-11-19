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
}
