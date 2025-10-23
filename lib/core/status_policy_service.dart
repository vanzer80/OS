import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'orders_service.dart';

class StatusPolicyService {
  StatusPolicyService(this._supabase);
  final SupabaseClient _supabase;

  // Cache em memória para evitar chamadas repetidas
  List<OrderStatus>? _cache;

  // Mapa de transições permitidas (regras de negócio)
  static const Map<OrderStatus, List<OrderStatus>> _allowedTransitions = {
    OrderStatus.pending: [
      OrderStatus.awaitingApproval,
      OrderStatus.awaitingPayment,
      OrderStatus.awaitingPart,
      OrderStatus.inProgress,
      OrderStatus.cancelled,
    ],
    OrderStatus.awaitingApproval: [
      OrderStatus.awaitingPayment,
      OrderStatus.awaitingPart,
      OrderStatus.inProgress,
      OrderStatus.cancelled,
    ],
    OrderStatus.awaitingPayment: [
      OrderStatus.awaitingPart,
      OrderStatus.inProgress,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ],
    OrderStatus.awaitingPart: [
      OrderStatus.inProgress,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ],
    OrderStatus.inProgress: [
      OrderStatus.awaitingPart,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ],
    OrderStatus.completed: [OrderStatus.cancelled],
    OrderStatus.cancelled: [],
  };

  Future<List<OrderStatus>> getAllowedStatuses({
    bool forceRefresh = false,
    Future<dynamic> Function()? fetch,
  }) async {
    if (!forceRefresh && _cache != null) return _cache!;
    try {
      final data = await (fetch != null
          ? fetch()
          : _supabase.rpc('get_allowed_statuses'));
      if (data is List && data.isNotEmpty) {
        // Parse the malformed response from RPC
        final List<OrderStatus> statuses = [];

        for (final item in data) {
          final str = item.toString();
          // Extract status values from malformed constraint expression
          // Expected format: "((status)::text=ANY((ARRAY[pending::charactervarying,in_progress::charactervarying,...]"
          if (str.contains('pending')) statuses.add(OrderStatus.pending);
          if (str.contains('awaiting_approval'))
            statuses.add(OrderStatus.awaitingApproval);
          if (str.contains('awaiting_payment'))
            statuses.add(OrderStatus.awaitingPayment);
          if (str.contains('awaiting_part'))
            statuses.add(OrderStatus.awaitingPart);
          if (str.contains('in_progress')) statuses.add(OrderStatus.inProgress);
          if (str.contains('completed')) statuses.add(OrderStatus.completed);
          if (str.contains('cancelled')) statuses.add(OrderStatus.cancelled);
        }

        // Remove duplicates and ensure we have at least the basic statuses
        final uniqueStatuses = statuses.toSet().toList();
        if (uniqueStatuses.isNotEmpty) {
          _cache = uniqueStatuses;
          return uniqueStatuses;
        }
      }
      // Fallback: expor todos os status conhecidos da aplicação
      _cache = OrderStatus.values.toList();
      return _cache!;
    } catch (_) {
      // Em caso de erro na RPC, usar fallback completo (não reduzir opções)
      _cache = OrderStatus.values.toList();
      return _cache!;
    }
  }

  bool isTransitionAllowed(OrderStatus from, OrderStatus to) {
    if (from == to) return true;
    final allowed = _allowedTransitions[from] ?? const [];
    return allowed.contains(to);
  }
}

final statusPolicyServiceProvider = Provider<StatusPolicyService>((ref) {
  return StatusPolicyService(Supabase.instance.client);
});

final allowedStatusesProvider = FutureProvider<List<OrderStatus>>((ref) async {
  final service = ref.read(statusPolicyServiceProvider);
  return service.getAllowedStatuses();
});
