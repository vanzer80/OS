import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OrderType { service, budget, sale }

// ===================== Dashboard Summary Models/Providers =====================
class DashboardSummary {
  final int ordersToday;
  final int pending;
  final int completed;
  final double monthlyRevenue;

  DashboardSummary({
    required this.ordersToday,
    required this.pending,
    required this.completed,
    required this.monthlyRevenue,
  });
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final service = ref.read(ordersServiceProvider);
  return service.getDashboardSummary();
});
enum OrderStatus { pending, inProgress, completed, cancelled }

class OrderImageRecord {
  final String url;
  final String? title;
  final String? description;
  final int position;

  OrderImageRecord({
    required this.url,
    required this.position,
    this.title,
    this.description,
  });

  factory OrderImageRecord.fromJson(Map<String, dynamic> json) => OrderImageRecord(
        url: json['url'],
        position: json['position'] ?? 0,
        title: json['title'],
        description: json['description'],
      );

  Map<String, dynamic> toRow(String orderId) => {
        'order_id': orderId,
        'url': url,
        'title': title,
        'description': description,
        'position': position,
      };
}

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

  // Geração de numeração: XXXX-YY onde XXXX é seq única por ano (reinicia em 0100) e YY são os dois dígitos do ano
  Future<(String,int,int)> _generateNumberByYear() async {
    try {
      final now = DateTime.now();
      final year = now.year;
      // Buscar máximo seq_per_year para este ano
      final resp = await _supabase
          .from('service_orders')
          .select('seq_per_year')
          .eq('fiscal_year', year)
          .order('seq_per_year', ascending: false)
          .limit(1);
      final lastSeq = (resp.isNotEmpty && resp.first['seq_per_year'] != null)
          ? (resp.first['seq_per_year'] as int)
          : 0;
      // Se não houver sequência anterior, iniciar em 0100
      final nextSeq = lastSeq > 0 ? lastSeq + 1 : 100;
      // Persistir no formato 0100-yy (4 dígitos + hífen + 2 dígitos do ano)
      final yy = year % 100;
      final formatted = '${nextSeq.toString().padLeft(4, '0')}-$yy';
      return (formatted, year, nextSeq);
    } catch (error) {
      final now = DateTime.now();
      final yy = now.year % 100;
      // Fallback seguro: começa em 0100
      return ('0100-$yy', now.year, 100);
    }
  }

  Future<ServiceOrder> createOrder(ServiceOrder order) async {
    try {
      // Gerar número por ano (único por ano)
      final (orderNumber, fiscalYear, seq) = await _generateNumberByYear();

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

  // ===================== Imagens da Ordem =====================
  Future<void> deleteImagesForOrder(String orderId) async {
    try {
      await _supabase.from('order_images').delete().eq('order_id', orderId);
    } catch (error) {
      throw Exception('Erro ao excluir imagens da ordem: $error');
    }
  }

  Future<void> addOrderImages(String orderId, List<String> urls) async {
    if (urls.isEmpty) return;
    try {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < urls.length; i++) {
        rows.add({
          'order_id': orderId,
          'url': urls[i],
          'position': i,
        });
      }
      await _supabase.from('order_images').insert(rows);
    } catch (error) {
      throw Exception('Erro ao salvar imagens da ordem: $error');
    }
  }

  Future<void> addOrderImagesWithMeta(String orderId, List<OrderImageRecord> records) async {
    if (records.isEmpty) return;
    try {
      final rows = records.map((r) => r.toRow(orderId)).toList();
      await _supabase.from('order_images').insert(rows);
    } catch (error) {
      throw Exception('Erro ao salvar imagens da ordem (meta): $error');
    }
  }

  Future<List<String>> getOrderImageUrls(String orderId) async {
    try {
      final response = await _supabase
          .from('order_images')
          .select('url, position')
          .eq('order_id', orderId)
          .order('position', ascending: true);
      final urls = (response as List).map((e) => (e['url'] as String)).toList();
      if (urls.isNotEmpty) return urls;

      // Fallback: listar do Storage caso a tabela esteja vazia (compatibilidade)
      try {
        final files = await _supabase.storage.from('order-images').list(path: 'orders/$orderId');
        return files
            .where((f) => !(f.name.startsWith('.') || f.name.isEmpty))
            .map((f) => _supabase.storage
                .from('order-images')
                .getPublicUrl('orders/$orderId/${f.name}'))
            .toList();
      } catch (_) {
        return urls; // continua vazio
      }
    } catch (error) {
      throw Exception('Erro ao buscar imagens da ordem: $error');
    }
  }

  Future<List<OrderImageRecord>> getOrderImages(String orderId) async {
    try {
      final response = await _supabase
          .from('order_images')
          .select('url, title, description, position')
          .eq('order_id', orderId)
          .order('position', ascending: true);
      final rows = (response as List).map((e) => OrderImageRecord.fromJson(e)).toList();
      if (rows.isNotEmpty) return rows;

      // Fallback: listar do Storage sem meta
      try {
        final files = await _supabase.storage.from('order-images').list(path: 'orders/$orderId');
        return files
            .where((f) => !(f.name.startsWith('.') || f.name.isEmpty))
            .toList()
            .asMap()
            .entries
            .map((entry) => OrderImageRecord(
                  url: _supabase.storage.from('order-images').getPublicUrl('orders/$orderId/${entry.value.name}'),
                  position: entry.key,
                ))
            .toList();
      } catch (_) {
        return rows; // vazio
      }
    } catch (error) {
      throw Exception('Erro ao buscar imagens da ordem (meta): $error');
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

  // ===================== Dashboard Summary =====================
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // 1) Ordens criadas hoje
      final todayRows = await _supabase
          .from('service_orders')
          .select('id')
          .gte('created_at', startOfToday.toIso8601String());
      final ordersToday = (todayRows as List).length;

      // 2) Abertas/Pendentes: considerar pending + in_progress
      final pendingRows = await _supabase
          .from('service_orders')
          .select('id')
          .or('status.eq.${OrderStatus.pending.name},status.eq.${OrderStatus.inProgress.name}');
      final pending = (pendingRows as List).length;

      // 3) Concluídas
      final completedRows = await _supabase
          .from('service_orders')
          .select('id')
          .eq('status', OrderStatus.completed.name);
      final completed = (completedRows as List).length;

      // 4) Faturamento (mês atual): soma de total_amount para ordens concluídas no mês
      final revenueRows = await _supabase
          .from('service_orders')
          .select('total_amount')
          .eq('status', OrderStatus.completed.name)
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', now.toIso8601String());
      final revenue = (revenueRows as List)
          .fold<double>(0.0, (sum, row) => sum + (((row['total_amount'] as num?)?.toDouble()) ?? 0.0));

      return DashboardSummary(
        ordersToday: ordersToday,
        pending: pending,
        completed: completed,
        monthlyRevenue: revenue,
      );
    } catch (error) {
      throw Exception('Erro ao carregar resumo do dashboard: $error');
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
