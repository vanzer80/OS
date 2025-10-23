import 'package:flutter_test/flutter_test.dart';
import 'package:os_express_flutter/core/finance_service.dart';

void main() {
  test('MonthlyPoint maps correctly', () {
    final m = {
      'year': 2025,
      'month': 10,
      'income_total': 1234.56,
      'expense_total': 234.5,
      'net_total': 1000.06,
    };
    final p = MonthlyPoint.fromMap(m);
    expect(p.year, 2025);
    expect(p.month, 10);
    expect(p.incomeTotal, 1234.56);
    expect(p.expenseTotal, 234.5);
    expect(p.netTotal, 1000.06);
  });

  test('FinanceDashboard maps correctly', () {
    final j = {
      'ok': true,
      'income_month': 2000.0,
      'expense_month': 500.0,
      'net_today': 300.0,
      'income_today': 350.0,
      'expense_today': 50.0,
    };
    final d = FinanceDashboard.fromJson(j);
    expect(d.incomeMonth, 2000.0);
    expect(d.expenseMonth, 500.0);
    expect(d.netToday, 300.0);
    expect(d.incomeToday, 350.0);
    expect(d.expenseToday, 50.0);
  });
}
