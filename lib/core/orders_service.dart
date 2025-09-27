import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OrderType { service, budget, sale }
enum OrderStatus { pending, inProgress, completed, cancelled }

class OrderItem {
  final String id;
  final String orderId;
  final String description;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      description: json['description'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'un',
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? description,
    int? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ServiceOrder {
  final String id;
  final String userId;
  final String? clientId;
  final String orderNumber;
  final OrderType type;
  final OrderStatus status;
  final String? equipment;
  final String? model;
  final String? brand; // Novo campo: Marca
  final String? serialNumber; // Novo campo: Número de Série
  final String? description;
  final String? paymentTerms; // Condições de pagamento
  final String? warranty; // Garantia
  final String? observations; // Observações
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? fiscalYear; // Ano fiscal
  final int? seqPerYear; // Sequência por ano/tipo

  ServiceOrder({
    required this.id,
    required this.userId,
    this.clientId,
    required this.orderNumber,
    required this.type,
    required this.status,
    this.equipment,
    this.model,
    this.brand, // Novo campo
    this.serialNumber, // Novo campo
    this.description,
    this.paymentTerms,
    this.warranty,
    this.observations,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.fiscalYear,
    this.seqPerYear,
  });

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      id: json['id'],
      userId: json['user_id'],
      clientId: json['client_id'],
      orderNumber: json['order_number'],
      type: OrderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OrderType.service,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      equipment: json['equipment'],
      model: json['model'],
      brand: json['brand'], // Novo campo
      serialNumber: json['serial_number'], // Novo campo
      description: json['description'],
      paymentTerms: json['payment_terms'],
      warranty: json['warranty'],
      observations: json['observations'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      fiscalYear: json['fiscal_year'],
      seqPerYear: json['seq_per_year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'client_id': clientId,
      'order_number': orderNumber,
      'type': type.name,
      'status': status.name,
      'equipment': equipment,
      'model': model,
      'brand': brand, // Novo campo
      'serial_number': serialNumber, // Novo campo
      'description': description,
      'payment_terms': paymentTerms,
      'warranty': warranty,
      'observations': observations,
      'total_amount': totalAmount,
      'fiscal_year': fiscalYear,
      'seq_per_year': seqPerYear,
    };
  }

  ServiceOrder copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? orderNumber,
    OrderType? type,
    OrderStatus? status,
    String? equipment,
    String? model,
    String? brand, // Novo campo
    String? serialNumber, // Novo campo
    String? description,
    String? paymentTerms,
    String? warranty,
    String? observations,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? fiscalYear,
    int? seqPerYear,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      orderNumber: orderNumber ?? this.orderNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      model: model ?? this.model,
      brand: brand ?? this.brand, // Novo campo
      serialNumber: serialNumber ?? this.serialNumber, // Novo campo
      description: description ?? this.description,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      warranty: warranty ?? this.warranty,
      observations: observations ?? this.observations,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fiscalYear: fiscalYear ?? this.fiscalYear,
      seqPerYear: seqPerYear ?? this.seqPerYear,
    );
  }
}

class OrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<(String,int,int)> _generateNumberByTypeYear(OrderType type) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      // Buscar máximo seq_per_year para este tipo e ano
      final resp = await _supabase
          .from('service_orders')
          .select('seq_per_year')
          .eq('type', type.name)
          .eq('fiscal_year', year)
          .order('seq_per_year', ascending: false)
          .limit(1);
      final lastSeq = (resp.isNotEmpty && resp.first['seq_per_year'] != null)
          ? (resp.first['seq_per_year'] as int)
          : 0;
      // Se não houver sequência anterior, iniciar em 0301 (padrão solicitado)
      final nextSeq = lastSeq > 0 ? lastSeq + 1 : 301;
      // Persistir somente no formato 0001-yy (sem prefixos)
      final yy = year % 100;
      final formatted = '${nextSeq.toString().padLeft(4, '0')}-$yy';
      return (formatted, year, nextSeq);
    } catch (error) {
      final now = DateTime.now();
      final yy = now.year % 100;
      // Fallback seguro: começa em 0301 conforme padrão
      return ('0301-$yy', now.year, 301);
    }
  }

  Future<ServiceOrder> createOrder(ServiceOrder order) async {
    try {
      // Gerar número por tipo/ano
      final (orderNumber, fiscalYear, seq) = await _generateNumberByTypeYear(order.type);

      final orderData = {
        ...order.toJson(),
        'order_number': orderNumber,
        'status': OrderStatus.pending.name,
        'fiscal_year': fiscalYear,
        'seq_per_year': seq,
      };

      final response = await _supabase
          .from('service_orders')
          .insert(orderData)
          .select()
          .single();

      return ServiceOrder.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao criar ordem: $error');
    }
  }

  Future<List<ServiceOrder>> getOrders({
    String? clientId,
    OrderType? type,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('service_orders')
          .select();

      if (clientId != null) {
        queryBuilder = queryBuilder.eq('client_id', clientId);
      }

      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type.name);
      }

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.name);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      final response = await queryBuilder.order('created_at', ascending: false);
      return (response as List)
          .map((json) => ServiceOrder.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar ordens: $error');
    }
  }

  Future<ServiceOrder> updateOrder(String id, ServiceOrder order) async {
    try {
      final response = await _supabase
          .from('service_orders')
          .update({
            ...order.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return ServiceOrder.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao atualizar ordem: $error');
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _supabase
          .from('service_orders')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw Exception('Erro ao deletar ordem: $error');
    }
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => OrderItem.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar itens da ordem: $error');
    }
  }

  Future<OrderItem> createOrderItem(OrderItem item) async {
    try {
      final response = await _supabase
          .from('order_items')
          .insert(item.toJson())
          .select()
          .single();

      return OrderItem.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao criar item: $error');
    }
  }

  Future<OrderItem> updateOrderItem(String id, OrderItem item) async {
    try {
      final response = await _supabase
          .from('order_items')
          .update(item.toJson())
          .eq('id', id)
          .select()
          .single();

      return OrderItem.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao atualizar item: $error');
    }
  }

  Future<void> deleteOrderItem(String id) async {
    try {
      await _supabase
          .from('order_items')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw Exception('Erro ao deletar item: $error');
    }
  }

  Future<void> deleteOrderItems(String orderId) async {
    try {
      await _supabase
          .from('order_items')
          .delete()
          .eq('order_id', orderId);
    } catch (error) {
      throw Exception('Erro ao excluir itens da ordem: $error');
    }
  }

  Future<double> calculateOrderTotal(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select('total_price')
          .eq('order_id', orderId);

      final items = response as List;
      return items.fold<double>(0.0, (sum, item) => sum + (item['total_price'] as num).toDouble());
    } catch (error) {
      throw Exception('Erro ao calcular total: $error');
    }
  }
}

// Providers
final ordersServiceProvider = Provider<OrdersService>((ref) => OrdersService());

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<ServiceOrder>>>((ref) {
  return OrdersNotifier(ref.read(ordersServiceProvider));
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<ServiceOrder>>> {
  final OrdersService _ordersService;

  OrdersNotifier(this._ordersService) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders({
    String? clientId,
    OrderType? type,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final orders = await _ordersService.getOrders(
        clientId: clientId,
        type: type,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(orders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<ServiceOrder> createOrder(ServiceOrder order) async {
    try {
      final newOrder = await _ordersService.createOrder(order);
      await loadOrders(); // Recarregar lista
      return newOrder;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateOrder(String id, ServiceOrder order) async {
    try {
      await _ordersService.updateOrder(id, order);
      await loadOrders(); // Recarregar lista
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _ordersService.deleteOrder(id);
      await loadOrders(); // Recarregar lista
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
