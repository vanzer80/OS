import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'orders_service.dart';

class FiltersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<String>> getClientsForFilter() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final response = await _supabase
          .from('clients')
          .select('name')
          .eq('user_id', user.id)
          .order('name');

      return (response as List)
          .map((client) => client['name'] as String)
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar clientes para filtro: $error');
    }
  }

  Future<List<String>> getEquipmentsForFilter() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final response = await _supabase
          .from('service_orders')
          .select('equipment')
          .eq('user_id', user.id)
          .not('equipment', 'is', null)
          .order('equipment');

      return (response as List)
          .map((order) => order['equipment'] as String)
          .toSet()
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar equipamentos para filtro: $error');
    }
  }

  Future<List<String>> getModelsForFilter() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      final response = await _supabase
          .from('service_orders')
          .select('model')
          .eq('user_id', user.id)
          .not('model', 'is', null)
          .order('model');

      return (response as List)
          .map((order) => order['model'] as String)
          .toSet()
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar modelos para filtro: $error');
    }
  }

  Future<double> getMinOrderValue() async {
    try {
      final response = await _supabase
          .from('service_orders')
          .select('total_amount')
          .order('total_amount')
          .limit(1);

      if (response.isNotEmpty) {
        return (response.first['total_amount'] as num).toDouble();
      }
      return 0.0;
    } catch (error) {
      return 0.0;
    }
  }

  Future<double> getMaxOrderValue() async {
    try {
      final response = await _supabase
          .from('service_orders')
          .select('total_amount')
          .order('total_amount', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return (response.first['total_amount'] as num).toDouble();
      }
      return 10000.0; // Valor padrão
    } catch (error) {
      return 10000.0;
    }
  }
}

// Provider
final filtersServiceProvider = Provider<FiltersService>((ref) {
  return FiltersService();
});

// State para filtros
class FiltersState {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedClient;
  final String? selectedEquipment;
  final String? selectedModel;
  final String? selectedPhone;
  final double? minValue;
  final double? maxValue;
  final OrderType? selectedType;

  const FiltersState({
    this.startDate,
    this.endDate,
    this.selectedClient,
    this.selectedEquipment,
    this.selectedModel,
    this.selectedPhone,
    this.minValue,
    this.maxValue,
    this.selectedType,
  });

  FiltersState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? selectedClient,
    String? selectedEquipment,
    String? selectedModel,
    String? selectedPhone,
    double? minValue,
    double? maxValue,
    OrderType? selectedType,
  }) {
    return FiltersState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedClient: selectedClient ?? this.selectedClient,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedPhone: selectedPhone ?? this.selectedPhone,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

// Provider para estado dos filtros
final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>((ref) {
  return FiltersNotifier();
});

class FiltersNotifier extends StateNotifier<FiltersState> {
  FiltersNotifier() : super(const FiltersState());

  void updateFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? selectedClient,
    String? selectedEquipment,
    String? selectedModel,
    String? selectedPhone,
    double? minValue,
    double? maxValue,
    OrderType? selectedType,
  }) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      selectedClient: selectedClient,
      selectedEquipment: selectedEquipment,
      selectedModel: selectedModel,
      selectedPhone: selectedPhone,
      minValue: minValue,
      maxValue: maxValue,
      selectedType: selectedType,
    );
  }

  void clearFilters() {
    state = const FiltersState();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setValueRange(double? min, double? max) {
    state = state.copyWith(minValue: min, maxValue: max);
  }
}
