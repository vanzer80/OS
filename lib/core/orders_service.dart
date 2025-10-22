import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

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

enum OrderStatus {
  pending,
  awaitingApproval,
  awaitingPayment,
  awaitingPart,
  inProgress,
  completed,
  cancelled,
}

extension OrderStatusDbX on OrderStatus {
  String get dbName {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.awaitingApproval:
        return 'awaiting_approval';
      case OrderStatus.awaitingPayment:
        return 'awaiting_payment';
      case OrderStatus.awaitingPart:
        return 'awaiting_part';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'awaiting_approval':
        return OrderStatus.awaitingApproval;
      case 'awaiting_payment':
        return OrderStatus.awaitingPayment;
      case 'awaiting_part':
        return OrderStatus.awaitingPart;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'paid':
        // Mapear registros legados para 'completed'
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

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

  factory OrderImageRecord.fromJson(Map<String, dynamic> json) =>
      OrderImageRecord(
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
      status: OrderStatusDbX.fromDb(json['status'] as String?),
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
      'status': status.dbName,
      'equipment': equipment,
      'model': model,
      'brand': brand, // Novo campo
      'serial_number': serialNumber, // Novo campo
      'description': description,
      'payment_terms': paymentTerms,
      'warranty': warranty,
      'observations': observations,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
  final SupabaseClient _supabase;

  OrdersService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // Geração de numeração: XXXX-YY onde XXXX é seq única por ano (reinicia em 0100) e YY são os dois dígitos do ano
  Future<(String, int, int)> _generateNumberByYear() async {
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

  // Assinatura em tempo real de mudanças na tabela service_orders
  RealtimeChannel? _ordersChannel;
  void subscribeOrdersRealtime(void Function() onChange) {
    try {
      final user = _supabase.auth.currentUser;
      _ordersChannel ??= _supabase.channel('orders-changes');
      _ordersChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'service_orders',
            // Filtra por usuário (se disponível na versão da lib)
            // Para versões sem filtro, aplicamos callback universal
            // e o Notifier revalida lista pelo provider.
            callback: (_) => onChange(),
          )
          .subscribe();
    } catch (_) {
      // Silencioso: caso a assinatura falhe, o app segue funcionando
    }
  }

  Future<ServiceOrder> createOrder(ServiceOrder order) async {
    try {
      // Gerar número atômico via RPC no banco (único por ano)
      final now = DateTime.now();
      final fiscalYear = now.year;
      int seq;
      try {
        final seqResp = await _supabase.rpc(
          'get_next_order_seq',
          params: {'fy': fiscalYear},
        );
        seq = (seqResp as num).toInt();
      } catch (_) {
        // Fallback seguro: usa estratégia antiga por ano
        final (_, fy, s) = await _generateNumberByYear();
        seq = s;
      }
      final yy = fiscalYear % 100;
      final orderNumber = '${seq.toString().padLeft(4, '0')}-$yy';
      // Garantir persistência dos campos de pagamento/garantia com fallback do perfil
      String? pt = order.paymentTerms?.trim();
      String? wt = order.warranty?.trim();
      if ((pt == null || pt.isEmpty) || (wt == null || wt.isEmpty)) {
        try {
          final user = _supabase.auth.currentUser;
          if (user != null) {
            final profileRow = await _supabase
                .from('company_profiles')
                .select('default_payment_terms, default_warranty')
                .eq('user_id', user.id)
                .maybeSingle();
            if (profileRow != null) {
              pt = (pt == null || pt.isEmpty)
                  ? (profileRow['default_payment_terms'] as String?)
                  : pt;
              wt = (wt == null || wt.isEmpty)
                  ? (profileRow['default_warranty'] as String?)
                  : wt;
            }
          }
        } catch (_) {
          // Ignora fallback silenciosamente se não conseguir carregar perfil
        }
      }

      final orderData = {
        ...order.toJson(),
        'order_number': orderNumber,
        'status': OrderStatus.pending.dbName,
        'fiscal_year': fiscalYear,
        'seq_per_year': seq,
        // Override explícito para garantir persistência
        'payment_terms': pt,
        'warranty': wt,
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
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      var queryBuilder = _supabase
          .from('service_orders')
          .select()
          .eq('user_id', user.id);

      if (clientId != null) {
        queryBuilder = queryBuilder.eq('client_id', clientId);
      }

      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type.name);
      }

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.dbName);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte(
          'created_at',
          startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte(
          'created_at',
          endDate.toIso8601String(),
        );
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
      // Normaliza strings
      final normalized = {
        ...order.toJson(),
        'payment_terms': order.paymentTerms?.trim(),
        'warranty': order.warranty?.trim(),
      };

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final response = await _supabase
          .from('service_orders')
          .update({
            ...normalized,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();

      return ServiceOrder.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao atualizar ordem: $error');
    }
  }

  Future<ServiceOrder> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('[ERR_UNAUTH] Usuário não autenticado');
      }
      final response = await _supabase
          .from('service_orders')
          .update({
            'status': status.dbName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();
      return ServiceOrder.fromJson(response);
    } catch (error) {
      // Tenta mapear erros do Postgrest com códigos de forma robusta
      try {
        final dynamic e = error; // PostgrestException esperado
        final dynamic codeDyn = e.code; // pode ser String ou int
        final String? msg = e.message as String?;
        final String message = msg ?? error.toString();
        final String? details = e.details as String?;
        final String codeStr = codeDyn == null ? '' : codeDyn.toString();
        final bool isCheckViolation =
            codeStr == '23514' ||
            message.toLowerCase().contains('violates check constraint') ||
            message.toLowerCase().contains('check constraint') ||
            (details?.toLowerCase().contains('check constraint') ?? false);
        if (isCheckViolation) {
          throw Exception(
            '[ERR_STATUS_CHECK_VIOLATION] Status rejeitado pelo servidor. O status selecionado não é suportado pela configuração atual.',
          );
        }
        if (codeStr.isNotEmpty) {
          throw Exception(
            '[ERR_POSTGREST_$codeStr] Falha ao atualizar status: $message',
          );
        }
      } catch (_) {
        // Ignora se não for PostgrestException
      }
      throw Exception(
        '[ERR_UPDATE_STATUS_GENERIC] Erro ao atualizar status da ordem: $error',
      );
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      await _supabase
          .from('service_orders')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (error) {
      throw Exception('Erro ao deletar ordem: $error');
    }
  }

  // ===================== Itens da Ordem =====================
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
      throw Exception('Erro ao criar item da ordem: $error');
    }
  }

  Future<void> updateOrderItem(String id, OrderItem item) async {
    try {
      await _supabase.from('order_items').update(item.toJson()).eq('id', id);
    } catch (error) {
      throw Exception('Erro ao atualizar item da ordem: $error');
    }
  }

  Future<void> deleteOrderItem(String id) async {
    try {
      await _supabase.from('order_items').delete().eq('id', id);
    } catch (error) {
      throw Exception('Erro ao deletar item da ordem: $error');
    }
  }

  Future<void> deleteOrderItems(String orderId) async {
    try {
      await _supabase.from('order_items').delete().eq('order_id', orderId);
    } catch (error) {
      throw Exception('Erro ao deletar itens da ordem: $error');
    }
  }

  // ===================== Imagens da Ordem =====================
  // Helpers para geração de URLs assinadas de imagens
  String _pathFromPublicUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final idx = uri.pathSegments.indexOf(bucket);
      if (idx != -1 && idx + 1 < uri.pathSegments.length) {
        return uri.pathSegments.sublist(idx + 1).join('/');
      }
      return url;
    } catch (_) {
      return url;
    }
  }

  Future<String> _signedUrlForImage(
    String bucket,
    String urlOrPath, {
    int expiresInSeconds = 3600,
  }) async {
    final isUrl = urlOrPath.startsWith('http');
    final path = isUrl ? _pathFromPublicUrl(urlOrPath, bucket) : urlOrPath;
    final signed = await _supabase.storage
        .from(bucket)
        .createSignedUrl(path, expiresInSeconds);
    return signed;
  }

  Future<void> addOrderImagesWithMeta(
    String orderId,
    List<OrderImageRecord> records,
  ) async {
    try {
      if (records.isEmpty) return;
      final rows = records.map((r) => r.toRow(orderId)).toList();
      await _supabase.from('order_images').insert(rows);
    } catch (error) {
      throw Exception('Erro ao salvar imagens da ordem: $error');
    }
  }

  Future<List<OrderImageRecord>> getOrderImages(String orderId) async {
    try {
      final rows = await _supabase
          .from('order_images')
          .select()
          .eq('order_id', orderId)
          .order('position', ascending: true);

      final list = (rows as List);
      if (list.isNotEmpty) {
        final List<OrderImageRecord> out = [];
        for (var i = 0; i < list.length; i++) {
          final json = list[i] as Map<String, dynamic>;
          final urlOrPath = json['url'] as String?;
          final signed = urlOrPath == null
              ? null
              : await _signedUrlForImage(
                  SupabaseConfig.imagesBucket,
                  urlOrPath,
                  expiresInSeconds: 60 * 60,
                );
          out.add(
            OrderImageRecord(
              url: signed ?? urlOrPath ?? '',
              position: json['position'] ?? i,
              title: json['title'],
              description: json['description'],
            ),
          );
        }
        return out;
      }

      // Fallback: listar diretamente do Storage se tabela estiver vazia
      final files = await _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .list(path: 'orders/$orderId/');

      final List<OrderImageRecord> records = [];
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        final name = (f as dynamic).name as String;
        final signed = await _supabase.storage
            .from(SupabaseConfig.imagesBucket)
            .createSignedUrl('orders/$orderId/$name', 60 * 60);
        records.add(OrderImageRecord(url: signed, position: i));
      }
      return records;
    } catch (error) {
      throw Exception('Erro ao carregar imagens da ordem: $error');
    }
  }

  Future<void> deleteImagesForOrder(String orderId) async {
    try {
      await _supabase.from('order_images').delete().eq('order_id', orderId);
    } catch (error) {
      throw Exception('Erro ao deletar imagens da ordem: $error');
    }
  }

  // ===================== Dashboard Summary =====================
  Future<DashboardSummary> getDashboardSummary() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Quantidade de ordens criadas hoje
    final ordersTodayRows = await _supabase
        .from('service_orders')
        .select('id')
        .eq('user_id', user.id)
        .gte('created_at', startOfDay.toIso8601String());
    final ordersToday = (ordersTodayRows as List).length;

    // Pendentes (pending + in_progress)
    final pendingRows = await _supabase
        .from('service_orders')
        .select('id')
        .eq('user_id', user.id)
        .or('status.eq.pending,status.eq.in_progress');
    final pending = (pendingRows as List).length;

    // Concluídas
    final completedRows = await _supabase
        .from('service_orders')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'completed');
    final completed = (completedRows as List).length;

    // Receita do mês calculada por pagamentos (prioritário)
    final paidRows = await _supabase
        .from('payments')
        .select('amount, paid_at')
        .eq('user_id', user.id)
        .gte('paid_at', startOfMonth.toIso8601String())
        .lte('paid_at', now.toIso8601String());
    final monthlyRevenue = (paidRows as List).fold<double>(
      0.0,
      (sum, row) => sum + (((row['amount'] as num?)?.toDouble()) ?? 0.0),
    );

    return DashboardSummary(
      ordersToday: ordersToday,
      pending: pending,
      completed: completed,
      monthlyRevenue: monthlyRevenue,
    );
  }

  // ===================== Dashboard Aggregations =====================
  Future<StatusBreakdown> getStatusBreakdown() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final rows = await _supabase
          .from('service_orders')
          .select('status')
          .eq('user_id', user.id);
      int pending = 0;
      int awaitingApproval = 0;
      int awaitingPayment = 0;
      int awaitingPart = 0;
      int inProgress = 0;
      int completed = 0;
      int cancelled = 0;
      for (final row in (rows as List)) {
        final s = (row['status'] as String?) ?? '';
        final statusEnum = OrderStatusDbX.fromDb(s);
        if (statusEnum == OrderStatus.pending) {
          pending++;
        } else if (statusEnum == OrderStatus.awaitingApproval) awaitingApproval++;
        else if (statusEnum == OrderStatus.awaitingPayment) awaitingPayment++;
        else if (statusEnum == OrderStatus.awaitingPart) awaitingPart++;
        else if (statusEnum == OrderStatus.inProgress) inProgress++;
        else if (statusEnum == OrderStatus.completed) completed++;
        else if (statusEnum == OrderStatus.cancelled) cancelled++;
      }
      return StatusBreakdown(
        pending: pending,
        awaitingApproval: awaitingApproval,
        awaitingPayment: awaitingPayment,
        awaitingPart: awaitingPart,
        inProgress: inProgress,
        completed: completed,
        cancelled: cancelled,
      );
    } catch (error) {
      throw Exception('Erro ao carregar distribuição de status: $error');
    }
  }

  Future<List<MonthlyRevenuePoint>> getMonthlyRevenue({int months = 12}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);

    Future<List<MonthlyRevenuePoint>> fillFrom(Map<int, double> sums) async {
      final List<MonthlyRevenuePoint> points =
          sums.entries.map((e) {
            final year = e.key ~/ 100;
            final month = e.key % 100;
            return MonthlyRevenuePoint(
              year: year,
              month: month,
              value: e.value,
            );
          }).toList()..sort(
            (a, b) => (a.year == b.year)
                ? a.month.compareTo(b.month)
                : a.year.compareTo(b.year),
          );
      final List<MonthlyRevenuePoint> filled = [];
      for (int i = 0; i < months; i++) {
        final date = DateTime(now.year, now.month - months + 1 + i, 1);
        final existing = points.firstWhere(
          (p) => p.year == date.year && p.month == date.month,
          orElse: () => MonthlyRevenuePoint(
            year: date.year,
            month: date.month,
            value: 0.0,
          ),
        );
        filled.add(existing);
      }
      return filled;
    }

    try {
      // Preferir pagamentos (faturamento real)
      final rows = await _supabase
          .from('payments')
          .select('amount, paid_at')
          .eq('user_id', user.id)
          .gte('paid_at', start.toIso8601String())
          .lte('paid_at', now.toIso8601String());
      final Map<int, double> sums = {};
      for (final row in (rows as List)) {
        final paidAtStr = row['paid_at'] as String?;
        final amount = ((row['amount'] as num?)?.toDouble()) ?? 0.0;
        if (paidAtStr == null) continue;
        final paidAt = DateTime.tryParse(paidAtStr);
        if (paidAt == null) continue;
        final key = paidAt.year * 100 + paidAt.month;
        sums[key] = (sums[key] ?? 0.0) + amount;
      }
      return fillFrom(sums);
    } catch (error) {
      // Fallback: usar total_amount de ordens concluídas
      try {
        final rows = await _supabase
            .from('service_orders')
            .select('total_amount, created_at')
            .eq('user_id', user.id)
            .eq('status', OrderStatus.completed.dbName)
            .gte('created_at', start.toIso8601String())
            .lte('created_at', now.toIso8601String());
        final Map<int, double> sums = {};
        for (final row in (rows as List)) {
          final createdAtStr = row['created_at'] as String?;
          final amount = ((row['total_amount'] as num?)?.toDouble()) ?? 0.0;
          if (createdAtStr == null) continue;
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt == null) continue;
          final key = createdAt.year * 100 + createdAt.month;
          sums[key] = (sums[key] ?? 0.0) + amount;
        }
        return fillFrom(sums);
      } catch (fallbackError) {
        throw Exception(
          'Erro ao carregar faturamento mensal: $error | Fallback: $fallbackError',
        );
      }
    }
  }
}

class StatusBreakdown {
  final int pending;
  final int awaitingApproval;
  final int awaitingPayment;
  final int awaitingPart;
  final int inProgress;
  final int completed;
  final int cancelled;
  const StatusBreakdown({
    required this.pending,
    required this.awaitingApproval,
    required this.awaitingPayment,
    required this.awaitingPart,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
  });
  int get total =>
      pending +
      awaitingApproval +
      awaitingPayment +
      awaitingPart +
      inProgress +
      completed +
      cancelled;
}

class MonthlyRevenuePoint {
  final int year;
  final int month;
  final double value;
  const MonthlyRevenuePoint({
    required this.year,
    required this.month,
    required this.value,
  });
}

// Providers
final ordersServiceProvider = Provider<OrdersService>((ref) => OrdersService());

final statusBreakdownProvider = FutureProvider<StatusBreakdown>((ref) {
  final service = ref.read(ordersServiceProvider);
  return service.getStatusBreakdown();
});

final monthlyRevenueProvider = FutureProvider<List<MonthlyRevenuePoint>>((ref) {
  final service = ref.read(ordersServiceProvider);
  return service.getMonthlyRevenue(months: 12);
});

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<ServiceOrder>>>((
      ref,
    ) {
      return OrdersNotifier(ref.read(ordersServiceProvider));
    });

class OrdersNotifier extends StateNotifier<AsyncValue<List<ServiceOrder>>> {
  final OrdersService _ordersService;

  OrdersNotifier(this._ordersService) : super(const AsyncValue.loading()) {
    loadOrders();
    // Assina mudanças em tempo real para manter a UI sincronizada
    try {
      _ordersService.subscribeOrdersRealtime(() {
        // Recarrega lista ao detectar mudanças
        loadOrders();
      });
    } catch (_) {}
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

  Future<ServiceOrder> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final updated = await _ordersService.updateOrderStatus(id, status);
      await loadOrders();
      return updated;
    } catch (error) {
      // Não alterar o estado global da lista ao falhar uma atualização de status
      // para evitar que a tela entre em estado de erro completo. A UI chamadora
      // deve tratar a falha (SnackBar, etc.). Mantemos o estado atual.
      // Opcionalmente poderíamos logar o erro aqui.
      // debugPrint('Falha ao atualizar status: $error');
      // Preservar o estado anterior e propagar o erro.
      // Não fazer: state = AsyncValue.error(error, stackTrace);
      rethrow;
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
