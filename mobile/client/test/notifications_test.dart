import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tumai_market_client/config/app_config.dart';
import 'package:tumai_market_client/models/notification_model.dart';
import 'package:tumai_market_client/widgets/in_app_notification.dart';

void main() {
  test('notification endpoints point to the API', () {
    expect(AppConfig.notificationsEndpoint, '${AppConfig.apiUrl}/notifications');
    expect(AppConfig.notificationReadEndpoint('n1'),
        '${AppConfig.apiUrl}/notifications/n1/read');
  });

  test('NotificationModel reads an order update for the client', () {
    final n = NotificationModel.fromJson({
      '_id': 'n1',
      'type': 'order_updated',
      'title': 'Commande en livraison',
      'message': 'Votre commande ORD-000001 est en route',
      'order': {'_id': 'o1'},
      'createdAt': '2026-11-21T10:00:00Z',
    });
    expect(n.isOrderUpdate, isTrue);
    expect(n.orderId, 'o1');
    expect(n.isRead, isFalse);
    expect(n.markRead().isRead, isTrue);
  });

  testWidgets('order banner shows at the top and can be closed',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => InAppNotificationHost(child: child!),
      home: const Scaffold(body: Text('home')),
    ));

    InAppNotificationHost.show(
        title: 'Commande livrée', message: 'Merci pour votre achat');
    await tester.pumpAndSettle();
    expect(find.text('Commande livrée'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Commande livrée'), findsNothing);
  });
}
