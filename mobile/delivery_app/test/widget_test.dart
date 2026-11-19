import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumai_market_delivery/models/delivery_user_model.dart';
import 'package:tumai_market_delivery/models/notification_model.dart';
import 'package:tumai_market_delivery/models/order_model.dart';
import 'package:tumai_market_delivery/widgets/in_app_notification.dart';

Map<String, dynamic> _order({
  String status = 'ready',
  String? acceptedAt,
  String paymentMethod = 'cash',
  String paymentStatus = 'unpaid',
}) {
  return {
    '_id': 'o1',
    'orderNumber': 'ORD-000001',
    'status': status,
    'total': 15000,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'deliveryAddress': {
      'fullAddress': 'Avenue Charles de Gaulle',
      'quarter': 'Moursal',
      'city': 'N\'Djamena',
    },
    'client': {'_id': 'c1', 'name': 'Amina', 'phone': '+23566000000'},
    'merchant': {'_id': 'm1', 'shopName': 'Boutique Sahel', 'phone': '+23599000000'},
    'items': [
      {
        'product': {'_id': 'p1', 'name': 'Riz 5kg', 'images': ['https://x/y.jpg']},
        'quantity': 3,
        'price': 5000,
        'subtotal': 15000,
      },
    ],
    'deliveryAcceptedAt': acceptedAt,
  };
}

void main() {
  group('OrderModel delivery flow', () {
    test('new assignment awaits acceptance', () {
      final order = OrderModel.fromJson(_order());
      expect(order.isAwaitingAcceptance, isTrue);
      expect(order.isActiveDelivery, isFalse);
      expect(order.canPickUp, isFalse);
      expect(order.statusText, 'Nouvelle affectation');
    });

    test('accepted ready order can be picked up', () {
      final order =
          OrderModel.fromJson(_order(acceptedAt: '2026-11-19T10:00:00Z'));
      expect(order.isActiveDelivery, isTrue);
      expect(order.canPickUp, isTrue);
      expect(order.canMarkDelivered, isFalse);
    });

    test('in transit order can be marked delivered', () {
      final order = OrderModel.fromJson(
          _order(status: 'in_transit', acceptedAt: '2026-11-19T10:00:00Z'));
      expect(order.canPickUp, isFalse);
      expect(order.canMarkDelivered, isTrue);
    });

    test('delivered and cancelled orders are finished', () {
      for (final status in ['delivered', 'cancelled']) {
        final order = OrderModel.fromJson(_order(status: status));
        expect(order.isFinished, isTrue);
        expect(order.isAwaitingAcceptance, isFalse);
        expect(order.isActiveDelivery, isFalse);
      }
    });

    test('cash to collect only for unpaid cash orders', () {
      expect(OrderModel.fromJson(_order()).amountToCollect, 15000);
      expect(
          OrderModel.fromJson(_order(paymentStatus: 'paid')).amountToCollect, 0);
      expect(
          OrderModel.fromJson(_order(paymentMethod: 'mobile_money'))
              .amountToCollect,
          0);
    });

    test('parses populated contacts, items and address', () {
      final order = OrderModel.fromJson(_order());
      expect(order.merchant?.name, 'Boutique Sahel');
      expect(order.customerPhone, '+23566000000');
      expect(order.items.single.productName, 'Riz 5kg');
      expect(order.items.single.productImage, 'https://x/y.jpg');
      expect(order.addressText, 'Avenue Charles de Gaulle, Moursal, N\'Djamena');
      expect(order.subtotal, 15000);
    });

    test('accepts a legacy string address', () {
      final json = _order()..['deliveryAddress'] = 'Quartier Chagoua';
      expect(OrderModel.fromJson(json).addressText, 'Quartier Chagoua');
    });
  });

  group('DeliveryUserModel', () {
    test('must be approved and active to deliver', () {
      expect(DeliveryUserModel.fromJson({'isApproved': false}).canDeliver,
          isFalse);
      expect(
          DeliveryUserModel.fromJson({'isApproved': true, 'isActive': false})
              .canDeliver,
          isFalse);
      expect(DeliveryUserModel.fromJson({'isApproved': true}).canDeliver,
          isTrue);
    });

    test('round-trips through toJson (local storage)', () {
      final user = DeliveryUserModel.fromJson({
        'id': 'u1',
        'name': 'Ali',
        'phone': '+23566111111',
        'isApproved': true,
        'vehicleType': 'moto',
        'vehicleNumber': 'TD 1234',
      });
      final copy = DeliveryUserModel.fromJson(user.toJson());
      expect(copy.id, 'u1');
      expect(copy.vehicleTypeText, 'Moto');
      expect(copy.canDeliver, isTrue);
    });
  });

  test('NotificationModel reads order id from string or object', () {
    expect(NotificationModel.fromJson({'_id': 'n1', 'order': 'o1'}).orderId,
        'o1');
    expect(
        NotificationModel.fromJson({
          '_id': 'n2',
          'order': {'_id': 'o2'}
        }).orderId,
        'o2');
  });

  test('NotificationModel maps backend types', () {
    final assigned = NotificationModel.fromJson(
        {'_id': 'n', 'type': 'order_assigned', 'order': 'o1'});
    expect(assigned.isOrderAssigned, isTrue);
    expect(assigned.icon, Icons.delivery_dining);
    expect(NotificationModel.fromJson({'_id': 'n', 'type': 'account_rejected'})
        .isAccountUpdate, isTrue);
    expect(NotificationModel.fromJson({'_id': 'n', 'type': 'product_approved'})
        .isProductUpdate, isTrue);
  });

  testWidgets('in-app banner appears at the top, opens on tap, then hides',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => InAppNotificationHost(child: child!),
      home: const Scaffold(body: Text('home')),
    ));

    InAppNotificationHost.show(
      title: 'Nouvelle livraison assignée',
      message: 'Commande ORD-000001',
      onTap: () => tapped = true,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle livraison assignée'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Nouvelle livraison assignée')).dy,
        lessThan(100));

    await tester.tap(find.text('Commande ORD-000001'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(find.text('Nouvelle livraison assignée'), findsNothing);

    // Auto-dismiss after a few seconds
    InAppNotificationHost.show(title: 'Compte vérifié', message: 'ok');
    await tester.pumpAndSettle();
    expect(find.text('Compte vérifié'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Compte vérifié'), findsNothing);
  });
}
