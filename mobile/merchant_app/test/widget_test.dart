import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumai_market_merchant/models/notification_model.dart';
import 'package:tumai_market_merchant/models/order_model.dart';
import 'package:tumai_market_merchant/widgets/in_app_notification.dart';

void main() {
  group('OrderModel', () {
    test('parses the assigned delivery person', () {
      final order = OrderModel.fromJson({
        '_id': 'o1',
        'orderNumber': 'ORD-000001',
        'status': 'ready',
        'total': 10000,
        'deliveryAddress': {'fullAddress': 'Moursal', 'city': "N'Djamena"},
        'items': [
          {
            'product': {'_id': 'p1', 'name': 'Riz', 'images': []},
            'quantity': 2,
            'price': 5000,
            'subtotal': 10000,
          }
        ],
        'deliveryPerson': {
          '_id': 'd1',
          'name': 'Ali',
          'phone': '+23562222222',
          'vehicleType': 'moto',
          'vehicleNumber': 'TD 1234',
        },
        'deliveryAcceptedAt': '2026-11-19T10:00:00Z',
      });
      expect(order.hasDeliveryPerson, isTrue);
      expect(order.deliveryPerson!.vehicleText, 'Moto · TD 1234');
      expect(order.deliveryAcceptedAt, isNotNull);
      // subtotal is not stored by the backend: computed from the items
      expect(order.subtotal, 10000);
    });

    test('works without delivery person and with a text address', () {
      final order = OrderModel.fromJson({
        '_id': 'o2',
        'status': 'pending',
        'total': 5000,
        'deliveryAddress': 'Quartier Chagoua',
        'items': [],
      });
      expect(order.hasDeliveryPerson, isFalse);
      expect(order.deliveryAddress.fullAddress, 'Quartier Chagoua');
    });
  });

  test('NotificationModel maps backend types', () {
    final n = NotificationModel.fromJson(
        {'_id': 'n1', 'type': 'order_new', 'order': 'o1', 'title': 'Nouvelle commande'});
    expect(n.isOrderUpdate, isTrue);
    expect(n.orderId, 'o1');
    expect(NotificationModel.fromJson({'_id': 'n2', 'type': 'account_approved'})
        .isAccountUpdate, isTrue);
  });

  testWidgets('new order banner shows at the top of the app', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => InAppNotificationHost(child: child!),
      home: const Scaffold(body: Text('home')),
    ));

    InAppNotificationHost.show(
        title: 'Nouvelle commande', message: 'Commande ORD-000001');
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle commande'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle commande'), findsNothing);
  });
}
