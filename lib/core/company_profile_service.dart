import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyProfile {
  final String userId;
  final String name;
  final String? taxId;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? zip;
  final String? phone;
  final String? email;
  final String? contactName;
  final String? logoUrl;
  final String? signatureUrl;

  CompanyProfile({
    required this.userId,
    required this.name,
    this.taxId,
    this.addressLine,
    this.city,
    this.state,
    this.zip,
    this.phone,
    this.email,
    this.contactName,
    this.logoUrl,
    this.signatureUrl,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        userId: json['user_id'],
        name: json['name'],
        taxId: json['tax_id'],
        addressLine: json['address_line'],
        city: json['city'],
        state: json['state'],
        zip: json['zip'],
        phone: json['phone'],
        email: json['email'],
        contactName: json['contact_name'],
        logoUrl: json['logo_url'],
        signatureUrl: json['signature_url'],
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'tax_id': taxId,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'zip': zip,
        'phone': phone,
        'email': email,
        'contact_name': contactName,
        'logo_url': logoUrl,
        'signature_url': signatureUrl,
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
    final res = await _supabase
        .from('company_profiles')
        .upsert(profile.toJson())
        .select()
        .single();
    return CompanyProfile.fromJson(res);
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
}

final companyProfileServiceProvider = Provider<CompanyProfileService>((ref) => CompanyProfileService());
final companyProfileProvider = FutureProvider<CompanyProfile?>((ref) async {
  return ref.read(companyProfileServiceProvider).getProfile();
});
