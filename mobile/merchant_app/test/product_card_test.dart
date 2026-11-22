import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumai_market_merchant/models/product_model.dart';
import 'package:tumai_market_merchant/screens/products/products_screen.dart';

ProductModel _product(String name, double price, int stock, String status) =>
    ProductModel(
      id: name,
      name: name,
      description: '',
      price: price,
      categoryId: 'c',
      categoryName: 'Catégorie',
      merchantId: 'm',
      merchantName: 'Boutique',
      stock: stock,
      status: status,
      isApproved: status == 'approved',
    );

void main() {
  // Small phone width, normal font and the largest font the app allows
  for (final scale in [1.0, 1.2]) {
    testWidgets('product cards do not overflow (text x$scale)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final products = [
        _product('S26', 800000, 14, 'approved'),
        _product(
            'Ordinateur portable très puissant avec un nom vraiment long',
            1250000,
            0,
            'pending'),
        _product('Chaussure', 25000, 3, 'rejected'),
        _product('Riz parfumé 25 kg', 15000, 120, 'approved'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 740),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: productGridDelegate,
                itemCount: products.length,
                itemBuilder: (_, i) => ProductCard(product: products[i]),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // An overflow is reported as an exception during layout
      expect(tester.takeException(), isNull);
      expect(find.byType(ProductCard), findsNWidgets(4));
    });
  }
}
