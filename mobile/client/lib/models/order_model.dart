import 'usermodel.dart';

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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      items: (json['items'] as List?)
              ?.map((item) => OrderItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'cod',
      deliveryAddress: json['deliveryAddress'] is String
          ? AddressModel(
              label: json['deliveryAddress'],
              fullAddress: json['deliveryAddress'],
              city: '',
              quarter: null,
              details: null,
            )
          : AddressModel.fromJson(json['deliveryAddress'] ?? {}),
      notes: json['notes'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

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
      case 'picked':
        return 'Récupéré';
      case 'delivering':
        return 'En livraison';
      case 'delivered':
        return 'Livré';
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
    // Extract product image from images array or single image field
    String? productImage;
    if (json['product'] is Map &&
        (json['product']['images'] as List?)?.isNotEmpty == true) {
      productImage = (json['product']['images'] as List).first;
    } else if (json['productImage'] != null) {
      productImage = json['productImage'];
    } else if (json['product']?['image'] != null) {
      productImage = json['product']['image'];
    }

    return OrderItemModel(
      productId: json['productId'] ?? json['product']?['_id'] ?? '',
      productName: json['productName'] ?? json['product']?['name'] ?? '',
      productImage: productImage,
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
