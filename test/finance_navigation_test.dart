import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:os_express_flutter/features/finance/finance_dashboard_screen.dart';
import 'package:os_express_flutter/core/finance_service.dart';

void main() {
  testWidgets('FinanceDashboardScreen shows titles and actions', (tester) async {
    final fakeDashboard = FinanceDashboard(
      incomeMonth: 1000,
      expenseMonth: 200,
      netToday: 50,
      incomeToday: 60,
      expenseToday: 10,
    );

    final fakeMonthly = [
      MonthlyPoint(year: 2025, month: 8, incomeTotal: 1000, expenseTotal: 200, netTotal: 800),
      MonthlyPoint(year: 2025, month: 9, incomeTotal: 1500, expenseTotal: 300, netTotal: 1200),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeDashboardProvider.overrideWith((ref) async => fakeDashboard),
          financeMonthlySummaryProvider.overrideWith((ref) async => fakeMonthly),
        ],
        child: const MaterialApp(home: FinanceDashboardScreen()),
      ),
    );

    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Receitas (mês)'), findsOneWidget);
    expect(find.text('Despesas (mês)'), findsOneWidget);
    expect(find.text('Ações Rápidas'), findsOneWidget);
    expect(find.text('Nova Despesa'), findsOneWidget);
    expect(find.text('Transações'), findsOneWidget);
  });
}