import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';
import 'package:os_express_flutter/core/orders_service.dart';

void main() {
  group('OrderStatus mapping', () {
    test('dbName returns correct values', () {
      expect(OrderStatus.pending.dbName, 'pending');
      expect(OrderStatus.awaitingApproval.dbName, 'awaiting_approval');
      expect(OrderStatus.awaitingPayment.dbName, 'awaiting_payment');
      expect(OrderStatus.inProgress.dbName, 'in_progress');
      expect(OrderStatus.completed.dbName, 'completed');
      expect(OrderStatus.cancelled.dbName, 'cancelled');
    });

    test('fromDb maps strings to enum correctly', () {
      expect(OrderStatusDbX.fromDb('pending'), OrderStatus.pending);
      expect(
        OrderStatusDbX.fromDb('awaiting_approval'),
        OrderStatus.awaitingApproval,
      );
      expect(
        OrderStatusDbX.fromDb('awaiting_payment'),
        OrderStatus.awaitingPayment,
      );
      expect(OrderStatusDbX.fromDb('in_progress'), OrderStatus.inProgress);
      expect(OrderStatusDbX.fromDb('completed'), OrderStatus.completed);
      // Registros legados 'paid' devem mapear para 'completed'
      expect(OrderStatusDbX.fromDb('paid'), OrderStatus.completed);
      expect(OrderStatusDbX.fromDb('cancelled'), OrderStatus.cancelled);
    });
  });

  test('OrdersNotifier.updateOrderStatus updates status correctly', () async {
    final fake = _FakeOrdersService();
    final container = ProviderContainer(
      overrides: [ordersServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    // Aguarda carregamento inicial do notifier
    await Future.delayed(const Duration(milliseconds: 10));

    final notifier = container.read(ordersProvider.notifier);
    const orderId = 'abc';

    await notifier.updateOrderStatus(orderId, OrderStatus.awaitingPayment);
    expect(fake.lastStatus, OrderStatus.awaitingPayment);

    await notifier.updateOrderStatus(orderId, OrderStatus.completed);
    expect(fake.lastStatus, OrderStatus.completed);
  });
}

class _FakeOrdersService extends OrdersService {
  _FakeOrdersService()
    : super(
        supabase: SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

  OrderStatus? lastStatus;
  final List<ServiceOrder> _orders = [
    ServiceOrder(
      id: 'abc',
      userId: 'u1',
      clientId: null,
      orderNumber: '0100-25',
      type: OrderType.service,
      status: OrderStatus.pending,
      equipment: null,
      model: null,
      brand: null,
      serialNumber: null,
      description: 'desc',
      paymentTerms: null,
      warranty: null,
      observations: null,
      totalAmount: 123.45,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fiscalYear: DateTime.now().year,
      seqPerYear: 100,
    ),
  ];

  @override
  Future<List<ServiceOrder>> getOrders({
    String? clientId,
    OrderType? type,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _orders;
  }

  @override
  void subscribeOrdersRealtime(void Function() onChange) {
    // No-op in tests
  }

  @override
  Future<ServiceOrder> updateOrderStatus(String id, OrderStatus status) async {
    lastStatus = status;
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final updated = _orders[idx].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      _orders[idx] = updated;
      return updated;
    }
    final newOrder = _orders.first.copyWith(id: id, status: status);
    return newOrder;
  }
}
