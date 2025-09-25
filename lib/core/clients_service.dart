import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Client {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? document;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.document,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      document: json['document'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'document': document,
      'notes': notes,
    };
  }

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? document,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      document: document ?? this.document,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ClientsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Client>> getClients() async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Client.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar clientes: $error');
    }
  }

  Future<Client> getClientById(String id) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('id', id)
          .single();

      return Client.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao buscar cliente: $error');
    }
  }

  Future<Client> createClient(Client client) async {
    try {
      final response = await _supabase
          .from('clients')
          .insert({
            ...client.toJson(),
            'user_id': _supabase.auth.currentUser!.id,
          })
          .select()
          .single();

      return Client.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao criar cliente: $error');
    }
  }

  Future<Client> updateClient(String id, Client client) async {
    try {
      final response = await _supabase
          .from('clients')
          .update({
            ...client.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return Client.fromJson(response);
    } catch (error) {
      throw Exception('Erro ao atualizar cliente: $error');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _supabase
          .from('clients')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw Exception('Erro ao deletar cliente: $error');
    }
  }

  Future<List<Client>> searchClients(String query) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Client.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Erro ao buscar clientes: $error');
    }
  }
}

// Providers
final clientsServiceProvider = Provider<ClientsService>((ref) => ClientsService());

final clientsProvider = StateNotifierProvider<ClientsNotifier, AsyncValue<List<Client>>>((ref) {
  return ClientsNotifier(ref.read(clientsServiceProvider));
});

class ClientsNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  final ClientsService _clientsService;

  ClientsNotifier(this._clientsService) : super(const AsyncValue.loading()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = const AsyncValue.loading();
    try {
      final clients = await _clientsService.getClients();
      state = AsyncValue.data(clients);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createClient(Client client) async {
    try {
      await _clientsService.createClient(client);
      await loadClients(); // Recarregar lista
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateClient(String id, Client client) async {
    try {
      await _clientsService.updateClient(id, client);
      await loadClients(); // Recarregar lista
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _clientsService.deleteClient(id);
      await loadClients(); // Recarregar lista
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchClients(String query) async {
    if (query.isEmpty) {
      await loadClients();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final clients = await _clientsService.searchClients(query);
      state = AsyncValue.data(clients);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
