import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Payment {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String method;
  final String status;
  final DateTime paidAt;
  final DateTime createdAt;
  final String? methodNote;

  Payment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
    required this.createdAt,
    this.methodNote,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: (json['method'] as String?) ?? 'pix',
      status: (json['status'] as String?) ?? 'completed',
      paidAt: DateTime.parse(json['paid_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      methodNote: json['method_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'status': status,
      'paid_at': paidAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'method_note': methodNote,
    };
  }
}

class PaymentsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _paymentsChannel;

  // Compatível com uso existente na dashboard (sem filtros por ordem)
  void subscribePaymentsRealtime(void Function() onChange) {
    try {
      _paymentsChannel ??= _supabase.channel('payments-changes');
      _paymentsChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'payments',
            callback: (_) => onChange(),
          )
          .subscribe();
    } catch (_) {}
  }

  void disposePaymentsRealtime() {
    try {
      _paymentsChannel?.unsubscribe();
      _paymentsChannel = null;
    } catch (_) {}
  }

  Future<bool> hasPaidPayment(String orderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final rows = await _supabase
        .from('payments')
        .select('id')
        .eq('user_id', user.id)
        .eq('order_id', orderId)
        .eq('status', 'completed')
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  // NOVO: obter pagamentos por ordem (mais recentes primeiro)
  Future<List<Payment>> getPaymentsByOrder(String orderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final rows = await _supabase
        .from('payments')
        .select()
        .eq('user_id', user.id)
        .eq('order_id', orderId)
        .order('paid_at', ascending: false);
    return (rows as List).map((e) => Payment.fromJson(e)).toList();
  }

  Future<Payment> createPayment({
    required String orderId,
    required double amount,
    String method = 'pix',
    DateTime? paidAt,
    String? methodNote,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // Valida se a ordem pertence ao usuário e não está cancelada
    final orderRow = await _supabase
        .from('service_orders')
        .select('user_id, status')
        .eq('id', orderId)
        .maybeSingle();
    if (orderRow == null) {
      throw Exception('Ordem não encontrada');
    }
    if ((orderRow['user_id'] as String?) != user.id) {
      throw Exception('Ordem não pertence ao usuário atual');
    }
    final status = (orderRow['status'] as String?) ?? '';
    if (status == 'cancelled') {
      throw Exception(
        'Não é possível registrar pagamento para ordem cancelada',
      );
    }

    // Evita duplicidade de pagamento
    final already = await hasPaidPayment(orderId);
    if (already) {
      throw Exception('Pagamento já registrado para esta ordem');
    }

    final response = await _supabase
        .from('payments')
        .insert({
          'order_id': orderId,
          'user_id': user.id,
          'amount': amount,
          'method': method,
          'status': 'completed',
          'paid_at': (paidAt ?? DateTime.now()).toIso8601String(),
          'method_note': methodNote,
        })
        .select()
        .single();
    return Payment.fromJson(response);
  }
}

final paymentsServiceProvider = Provider<PaymentsService>(
  (ref) => PaymentsService(),
);
