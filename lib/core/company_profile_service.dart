import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyProfile {
  final String userId;
  final String name;
  final String? taxId;
  final String? addressLine; // legado
  final String? street;
  final String? streetNumber;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? zip;
  final String? phone;
  final String? email;
  final String? contactName;
  final String? logoUrl;
  final String? signatureUrl;
  // Defaults for orders
  final String? defaultPaymentTerms;
  final String? defaultWarranty;

  CompanyProfile({
    required this.userId,
    required this.name,
    this.taxId,
    this.addressLine,
    this.street,
    this.streetNumber,
    this.neighborhood,
    this.city,
    this.state,
    this.zip,
    this.phone,
    this.email,
    this.contactName,
    this.logoUrl,
    this.signatureUrl,
    this.defaultPaymentTerms,
    this.defaultWarranty,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        userId: json['user_id'],
        name: json['name'],
        taxId: json['tax_id'],
        addressLine: json['address_line'],
        street: json['street'],
        streetNumber: json['street_number'],
        neighborhood: json['neighborhood'],
        city: json['city'],
        state: json['state'],
        zip: json['zip'],
        phone: json['phone'],
        email: json['email'],
        contactName: json['contact_name'],
        logoUrl: json['logo_url'],
        signatureUrl: json['signature_url'],
        defaultPaymentTerms: json['default_payment_terms'],
        defaultWarranty: json['default_warranty'],
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'tax_id': taxId,
        'address_line': addressLine,
        'street': street,
        'street_number': streetNumber,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zip': zip,
        'phone': phone,
        'email': email,
        'contact_name': contactName,
        'logo_url': logoUrl,
        'signature_url': signatureUrl,
        'default_payment_terms': defaultPaymentTerms,
        'default_warranty': defaultWarranty,
      };
}

class CompanyProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const bucket = 'company-assets';

  Future<CompanyProfile?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final res = await _supabase
        .from('company_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (res == null) return null;
    return CompanyProfile.fromJson(res);
  }

  Future<CompanyProfile> upsertProfile(CompanyProfile profile) async {
    // Tenta salvar com todos os campos; se a tabela não tiver as novas colunas,
    // faz fallback para salvar apenas os campos existentes.
    Map<String, dynamic> payload = profile.toJson();
    try {
      final res = await _supabase
          .from('company_profiles')
          .upsert(payload)
          .select()
          .single();
      return CompanyProfile.fromJson(res);
    } catch (e) {
      // Fallback: remove campos que podem não existir ainda no schema
      payload.remove('default_payment_terms');
      payload.remove('default_warranty');
      final res = await _supabase
          .from('company_profiles')
          .upsert(payload)
          .select()
          .single();
      return CompanyProfile.fromJson(res);
    }
  }

  Future<String> uploadLogo(Uint8List bytes, {String fileName = 'logo.png'}) async {
    final user = _supabase.auth.currentUser!;
    final path = '${user.id}/$fileName';
    await _supabase.storage.from(bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/png', upsert: true));
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadSignature(Uint8List bytes, {String fileName = 'signature.png'}) async {
    final user = _supabase.auth.currentUser!;
    final path = '${user.id}/$fileName';
    await _supabase.storage.from(bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/png', upsert: true));
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  // Stream de perfil para sincronização em tempo real
  Stream<CompanyProfile?> getProfileStream() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }
    final stream = _supabase
        .from('company_profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id);
    yield* stream.map((rows) {
      if (rows.isEmpty) return null;
      return CompanyProfile.fromJson(rows.first);
    });
  }
}

final companyProfileServiceProvider = Provider<CompanyProfileService>((ref) => CompanyProfileService());
final companyProfileProvider = FutureProvider<CompanyProfile?>((ref) async {
  return ref.read(companyProfileServiceProvider).getProfile();
});
final companyProfileStreamProvider = StreamProvider<CompanyProfile?>((ref) {
  return ref.read(companyProfileServiceProvider).getProfileStream();
});
