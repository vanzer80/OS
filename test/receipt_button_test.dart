import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:os_express_flutter/features/orders/order_details_screen.dart';
import 'package:os_express_flutter/core/orders_service.dart';

void main() {
  testWidgets('Exibe botão Transformar em Recibo no AppBar e nas ações grandes', (tester) async {
    final fakeOrder = ServiceOrder(
      id: 'order_1',
      userId: 'user_1',
      clientId: 'client_1',
      orderNumber: 123,
      type: OrderType.service,
      status: OrderStatus.pending,
      totalAmount: 0.0,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(),
        ),
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SizedBox(),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OrderDetailsScreen(order: fakeOrder),
        ),
      ),
    );

    // Verifica ícone no AppBar
    expect(find.byIcon(Icons.receipt_long), findsWidgets);
    // Verifica label do botão grande
    expect(find.text('Transformar em Recibo'), findsOneWidget);
  });
}