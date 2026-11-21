import 'package:flutter/material.dart';
import '../config/theme.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? orderId;
  final String? productId;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'general',
    this.orderId,
    this.productId,
    this.isRead = false,
    this.createdAt,
  });

  static String? _idOf(dynamic ref) {
    // A reference may be an id string or a populated object
    if (ref is String) return ref;
    if (ref is Map) return ref['_id']?.toString();
    return null;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? json['body'] ?? '',
      type: json['type'] ?? 'general',
      orderId: _idOf(json['order'] ?? json['orderId']),
      productId: _idOf(json['product']),
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  NotificationModel markRead() {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      orderId: orderId,
      productId: productId,
      isRead: true,
      createdAt: createdAt,
    );
  }

  // Types sent by the backend (constants NOTIFICATION_TYPES)
  bool get isOrderAssigned => type == 'order_assigned';
  bool get isOrderUpdate =>
      type == 'order_updated' || type == 'order_cancelled' || type == 'order_new';
  bool get isAccountUpdate =>
      type == 'account_approved' || type == 'account_rejected';
  bool get isProductUpdate =>
      type == 'product_approved' || type == 'product_rejected';

  IconData get icon {
    switch (type) {
      case 'order_assigned':
        return Icons.delivery_dining;
      case 'order_new':
        return Icons.shopping_bag_rounded;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'order_updated':
        return Icons.receipt_long;
      case 'account_approved':
        return Icons.verified_user;
      case 'account_rejected':
        return Icons.gpp_bad_outlined;
      case 'product_approved':
        return Icons.inventory_2_rounded;
      case 'product_rejected':
        return Icons.remove_shopping_cart_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'order_assigned':
      case 'order_new':
        return AppTheme.secondaryColor;
      case 'order_cancelled':
      case 'account_rejected':
      case 'product_rejected':
        return AppTheme.errorColor;
      case 'account_approved':
      case 'product_approved':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
