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
  final String paymentStatus;
  final AddressModel deliveryAddress;
  final String? deliveryPhone;
  final String? notes;
  final OrderContact? client;
  final OrderContact? merchant;
  final DateTime? assignedAt;
  final DateTime? deliveryAcceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
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
    this.paymentMethod = 'cash',
    this.paymentStatus = 'unpaid',
    required this.deliveryAddress,
    this.deliveryPhone,
    this.notes,
    this.client,
    this.merchant,
    this.assignedAt,
    this.deliveryAcceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((item) => OrderItemModel.fromJson(item))
            .toList() ??
        [];
    final itemsTotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      items: items,
      subtotal: _toDouble(json['subtotal']) ?? itemsTotal,
      deliveryFee: _toDouble(json['deliveryFee']) ?? 0,
      total: _toDouble(json['total']) ?? itemsTotal,
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      deliveryAddress: _parseAddress(json['deliveryAddress']),
      deliveryPhone: json['deliveryPhone'],
      notes: json['notes'],
      client: OrderContact.tryParse(json['client']),
      merchant: OrderContact.tryParse(json['merchant']),
      assignedAt: _toDate(json['assignedAt']),
      deliveryAcceptedAt: _toDate(json['deliveryAcceptedAt']),
      pickedUpAt: _toDate(json['pickedUpAt']),
      deliveredAt: _toDate(json['deliveredAt']),
      cancelledAt: _toDate(json['cancelledAt']),
      cancelReason: json['cancelReason'],
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  // Older orders stored the address as a plain string
  static AddressModel _parseAddress(dynamic value) {
    if (value is Map<String, dynamic>) return AddressModel.fromJson(value);
    if (value is String) {
      return AddressModel(label: value, fullAddress: value, city: '');
    }
    return AddressModel(label: '', fullAddress: '', city: '');
  }

  String get statusText {
    if (isAwaitingAcceptance) return 'Nouvelle affectation';
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prêt à récupérer';
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

  String get paymentMethodText {
    switch (paymentMethod) {
      case 'cash':
      case 'cod':
        return 'Paiement à la livraison';
      case 'mobile_money':
        return 'Mobile Money';
      case 'card':
        return 'Carte bancaire';
      default:
        return paymentMethod;
    }
  }

  /// Amount the delivery person must collect from the customer.
  double get amountToCollect =>
      (paymentMethod == 'cash' || paymentMethod == 'cod') &&
              paymentStatus != 'paid'
          ? total
          : 0;

  /// Phone to reach the customer: explicit delivery phone, else account phone.
  String? get customerPhone =>
      (deliveryPhone != null && deliveryPhone!.isNotEmpty)
          ? deliveryPhone
          : client?.phone;

  String get addressText {
    final parts = [
      deliveryAddress.fullAddress,
      deliveryAddress.quarter,
      deliveryAddress.city,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return deliveryAddress.label;
    return parts.join(', ');
  }

  bool get isFinished =>
      ['delivered', 'completed', 'cancelled', 'rejected'].contains(status);

  /// Assigned by the admin but not yet accepted by the delivery person.
  bool get isAwaitingAcceptance => deliveryAcceptedAt == null && !isFinished;

  /// Accepted and still to be delivered.
  bool get isActiveDelivery => deliveryAcceptedAt != null && !isFinished;

  bool get canPickUp =>
      isActiveDelivery && ['confirmed', 'preparing', 'ready'].contains(status);

  bool get canMarkDelivered => isActiveDelivery && status == 'in_transit';

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Client or merchant info populated on the order.
class OrderContact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  OrderContact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  static OrderContact? tryParse(dynamic json) {
    if (json is! Map) return null;
    return OrderContact(
      id: json['_id']?.toString() ?? '',
      name: (json['shopName'] ?? json['name'] ?? '').toString(),
      phone: (json['shopPhone'] ?? json['phone'])?.toString(),
      email: json['email']?.toString(),
      address: (json['shopAddress'] ?? json['address'])?.toString(),
    );
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

    final price = (json['price'] ?? 0).toDouble();
    final quantity = (json['quantity'] ?? 1) as int;

    return OrderItemModel(
      productId: json['productId'] ??
          (product is Map ? product['_id'] : product is String ? product : null) ??
          '',
      productName: json['productName'] ??
          (product is Map ? product['name'] : null) ??
          'Produit',
      productImage: image,
      price: price,
      quantity: quantity,
      subtotal: (json['subtotal'] ?? price * quantity).toDouble(),
    );
  }
}
