import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceCategory {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' | 'expense'
  final DateTime createdAt;

  FinanceCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory FinanceCategory.fromMap(Map<String, dynamic> m) => FinanceCategory(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        type: m['type'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };
}

class Expense {
  final String id;
  final String userId;
  final String? categoryId;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        categoryId: m['category_id'] as String?,
        description: m['description'] as String,
        amount: (m['amount'] as num).toDouble(),
        expenseDate: DateTime.parse(m['expense_date'] as String),
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'description': description,
        'amount': amount,
        'expense_date': expenseDate.toIso8601String(),
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class LedgerItem {
  final String id;
  final String type; // 'income' | 'expense'
  final double amount;
  final DateTime entryDate;
  final String description;

  LedgerItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.entryDate,
    required this.description,
  });

  factory LedgerItem.fromMap(Map<String, dynamic> m) => LedgerItem(
        id: m['id'] as String,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        entryDate: DateTime.parse(m['entry_date'] as String),
        description: m['description'] as String,
      );
}

class MonthlyPoint {
  final int year;
  final int month;
  final double incomeTotal;
  final double expenseTotal;
  final double netTotal;

  MonthlyPoint({
    required this.year,
    required this.month,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.netTotal,
  });

  factory MonthlyPoint.fromMap(Map<String, dynamic> m) => MonthlyPoint(
        year: (m['year'] as num).toInt(),
        month: (m['month'] as num).toInt(),
        incomeTotal: (m['income_total'] as num).toDouble(),
        expenseTotal: (m['expense_total'] as num).toDouble(),
        netTotal: (m['net_total'] as num).toDouble(),
      );
}

class FinanceDashboard {
  final double incomeMonth;
  final double expenseMonth;
  final double netToday;
  final double incomeToday;
  final double expenseToday;

  FinanceDashboard({
    required this.incomeMonth,
    required this.expenseMonth,
    required this.netToday,
    required this.incomeToday,
    required this.expenseToday,
  });

  factory FinanceDashboard.fromJson(Map<String, dynamic> j) => FinanceDashboard(
        incomeMonth: ((j['income_month'] as num?) ?? 0).toDouble(),
        expenseMonth: ((j['expense_month'] as num?) ?? 0).toDouble(),
        netToday: ((j['net_today'] as num?) ?? 0).toDouble(),
        incomeToday: ((j['income_today'] as num?) ?? 0).toDouble(),
        expenseToday: ((j['expense_today'] as num?) ?? 0).toDouble(),
      );
}

class FinanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FinanceCategory>> getCategories({String? type}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    PostgrestFilterBuilder query = _supabase
        .from('financial_categories')
        .select()
        .eq('user_id', user.id);
    if (type != null) {
      query = query.eq('type', type);
    }
    final rows = await query.order('created_at', ascending: true);
    return (rows as List).map((e) => FinanceCategory.fromMap(e)).toList();
  }

  Future<FinanceCategory> upsertCategory({required String name, required String type}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final row = await _supabase
        .from('financial_categories')
        .upsert({
          'user_id': user.id,
          'name': name.trim(),
          'type': type,
        }, onConflict: 'user_id,name,type')
        .select()
        .single();
    return FinanceCategory.fromMap(row);
  }

  Future<void> deleteCategory(String categoryId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    await _supabase
        .from('financial_categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', user.id);
  }

  Future<FinanceCategory> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final row = await _supabase
        .from('financial_categories')
        .update({'name': name.trim()})
        .eq('id', categoryId)
        .eq('user_id', user.id)
        .select()
        .single();
    return FinanceCategory.fromMap(row);
  }

  Future<Expense> createExpense({
    String? categoryId,
    required String description,
    required double amount,
    DateTime? expenseDate,
    String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final row = await _supabase
        .from('expenses')
        .insert({
          'user_id': user.id,
          'category_id': categoryId,
          'description': description,
          'amount': amount,
          'expense_date': (expenseDate ?? DateTime.now()).toIso8601String(),
          'note': note,
        })
        .select()
        .single();
    return Expense.fromMap(row);
  }

  Future<List<Expense>> getExpenses({DateTime? start, DateTime? end, String? categoryId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    PostgrestFilterBuilder query = _supabase
        .from('expenses')
        .select()
        .eq('user_id', user.id);
    if (start != null) query = query.gte('expense_date', start.toIso8601String());
    if (end != null) query = query.lte('expense_date', end.toIso8601String());
    if (categoryId != null) query = query.eq('category_id', categoryId);
    final rows = await query.order('expense_date', ascending: false);
    return (rows as List).map((e) => Expense.fromMap(e)).toList();
  }

  Future<void> deleteExpense(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    await _supabase.from('expenses').delete().eq('id', id).eq('user_id', user.id);
  }

  Future<List<LedgerItem>> getLedger({DateTime? start, DateTime? end}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    PostgrestFilterBuilder query = _supabase
        .from('finance_ledger_view')
        .select()
        .eq('user_id', user.id);
    if (start != null) query = query.gte('entry_date', start.toIso8601String());
    if (end != null) query = query.lte('entry_date', end.toIso8601String());
    final rows = await query.order('entry_date', ascending: false);
    return (rows as List).map((e) => LedgerItem.fromMap(e)).toList();
  }

  Future<List<MonthlyPoint>> getMonthlySummary() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final rows = await _supabase
        .from('finance_monthly_summary')
        .select()
        .order('year', ascending: true)
        .order('month', ascending: true);
    return (rows as List).map((e) => MonthlyPoint.fromMap(e)).toList();
  }

  Future<FinanceDashboard> getDashboard() async {
    final res = await _supabase.rpc('get_finance_dashboard') as Map<String, dynamic>;
    if (res['ok'] != true) throw Exception('Falha ao carregar dashboard financeiro');
    return FinanceDashboard.fromJson(res);
  }
}

final financeServiceProvider = Provider<FinanceService>((ref) => FinanceService());

final financeMonthlySummaryProvider = FutureProvider<List<MonthlyPoint>>((ref) async {
  final svc = ref.read(financeServiceProvider);
  return svc.getMonthlySummary();
});

final financeDashboardProvider = FutureProvider<FinanceDashboard>((ref) async {
  final svc = ref.read(financeServiceProvider);
  return svc.getDashboard();
});

final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final svc = ref.read(financeServiceProvider);
  return svc.getExpenses();
});