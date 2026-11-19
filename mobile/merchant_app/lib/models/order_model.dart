import 'user_model.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final AddressModel deliveryAddress;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Delivery (assigned by the admin)
  final DeliveryPersonInfo? deliveryPerson;
  final DateTime? deliveryAcceptedAt;
  final DateTime? pickedUpAt;
  final String? cancelReason;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.total,
    this.paymentMethod = 'cod',
    required this.deliveryAddress,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deliveryPerson,
    this.deliveryAcceptedAt,
    this.pickedUpAt,
    this.cancelReason,
  });

  static DateTime? _date(dynamic value) =>
      value != null ? DateTime.tryParse(value.toString()) : null;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((item) => OrderItemModel.fromJson(item))
            .toList() ??
        [];
    final itemsTotal = items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final address = json['deliveryAddress'];

    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      items: items,
      // The backend only stores the total: fall back to the sum of the items
      subtotal: (json['subtotal'] ?? itemsTotal).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? itemsTotal).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'cod',
      deliveryAddress: address is String
          ? AddressModel.fromJson({'label': address, 'fullAddress': address})
          : AddressModel.fromJson(address ?? {}),
      notes: json['notes'],
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      deliveryPerson: json['deliveryPerson'] is Map
          ? DeliveryPersonInfo.fromJson(
              Map<String, dynamic>.from(json['deliveryPerson']))
          : null,
      deliveryAcceptedAt: _date(json['deliveryAcceptedAt']),
      pickedUpAt: _date(json['pickedUpAt']),
      cancelReason: json['cancelReason'],
    );
  }

  /// Once a delivery person is assigned, they confirm pickup and delivery
  bool get hasDeliveryPerson => deliveryPerson != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress.toJson(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prêt';
      case 'in_transit':
        return 'En livraison';
      case 'delivered':
        return 'Livré';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class DeliveryPersonInfo {
  final String id;
  final String name;
  final String phone;
  final String? vehicleType;
  final String? vehicleNumber;

  DeliveryPersonInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.vehicleType,
    this.vehicleNumber,
  });

  factory DeliveryPersonInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryPersonInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Livreur',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'],
      vehicleNumber: json['vehicleNumber'],
    );
  }

  String get vehicleText {
    const labels = {'moto': 'Moto', 'velo': 'Vélo', 'voiture': 'Voiture'};
    final type = labels[vehicleType] ?? '';
    if (vehicleNumber == null || vehicleNumber!.isEmpty) return type;
    return type.isEmpty ? vehicleNumber! : '$type · $vehicleNumber';
  }
}

class OrderItemModel {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Product image: try direct field, then populated 'images' array, then 'image' field
    final product = json['product'];
    String? image = json['productImage'];
    if (image == null && product is Map) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        image = images[0] as String?;
      }
      image ??= product['image'] as String?;
    }

    return OrderItemModel(
      productId: json['productId'] ?? (product is Map ? product['_id'] : null) ?? '',
      productName: json['productName'] ?? (product is Map ? product['name'] : null) ?? '',
      productImage: image,
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
