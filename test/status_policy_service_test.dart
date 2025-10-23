import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:os_express_flutter/core/orders_service.dart';
import 'package:os_express_flutter/core/status_policy_service.dart';

void main() {
  group('StatusPolicyService', () {
    // Cliente Supabase dummy (não será usado nos testes com fetch override)
    final dummyClient = SupabaseClient('http://localhost:54321', 'anon');

    test('getAllowedStatuses usa fetch override e faz cache', () async {
      int calls = 0;
      Future<dynamic> fakeFetch() async {
        calls++;
        return ['pending', 'completed'];
      }

      final service = StatusPolicyService(dummyClient);

      final s1 = await service.getAllowedStatuses(forceRefresh: true, fetch: fakeFetch);
      expect(s1, equals([OrderStatus.pending, OrderStatus.completed]));

      // Segunda chamada sem forceRefresh deve retornar do cache
      final s2 = await service.getAllowedStatuses(fetch: fakeFetch);
      expect(s2, equals(s1));
      expect(calls, 1);
    });

    test('getAllowedStatuses cai em fallback quando fetch lança exceção', () async {
      Future<dynamic> failingFetch() async {
        throw Exception('falha');
      }

      final service = StatusPolicyService(dummyClient);
      final s = await service.getAllowedStatuses(forceRefresh: true, fetch: failingFetch);
      expect(s, equals(OrderStatus.values));
    });

    test('isTransitionAllowed aplica regras de negócio locais', () {
      final service = StatusPolicyService(dummyClient);
      expect(service.isTransitionAllowed(OrderStatus.pending, OrderStatus.completed), isFalse);
      expect(service.isTransitionAllowed(OrderStatus.inProgress, OrderStatus.completed), isTrue);
    });
  });
}