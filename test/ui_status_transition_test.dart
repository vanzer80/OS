import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:os_express_flutter/core/orders_service.dart';

String statusText(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pendente';
    case OrderStatus.awaitingApproval:
      return 'Aguardando Aprovação';
    case OrderStatus.awaitingPayment:
      return 'Aguardando Pagamento';
    case OrderStatus.inProgress:
      return 'Em Andamento';
    case OrderStatus.completed:
      return 'Concluída';
    case OrderStatus.cancelled:
      return 'Cancelada';
  }
}

class TestMenu extends StatelessWidget {
  const TestMenu({super.key, required this.isAllowed});

  final bool Function(OrderStatus from, OrderStatus to) isAllowed;

  @override
  Widget build(BuildContext context) {
    final currentStatus = OrderStatus.pending;
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value.startsWith('status_')) {
          final db = value.substring(7);
          final target = OrderStatusDbX.fromDb(db);
          if (!isAllowed(currentStatus, target)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Transição de '${statusText(currentStatus)}' para '${statusText(target)}' não permitida.",
                ),
              ),
            );
            return;
          }
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        for (final s in OrderStatus.values) {
          items.add(
            PopupMenuItem(
              value: 'status_${s.dbName}',
              child: Text('Status: ${statusText(s)}'),
            ),
          );
        }
        return items;
      },
    );
  }
}

void main() {
  testWidgets('Exibe SnackBar quando transição inválida é selecionada', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: TestMenu(isAllowed: _policy)),
        ),
      ),
    );

    // Abre o menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    // Seleciona "Status: Concluída"
    await tester.tap(find.text('Status: Concluída'));
    await tester.pumpAndSettle();

    // Verifica SnackBar
    expect(
      find.text("Transição de 'Pendente' para 'Concluída' não permitida."),
      findsOneWidget,
    );
  });
}

bool _policy(OrderStatus from, OrderStatus to) {
  // Bloqueia explicitamente Pendente -> Concluída
  if (from == OrderStatus.pending && to == OrderStatus.completed) return false;
  return true;
}
