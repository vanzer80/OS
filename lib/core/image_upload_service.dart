import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Upload (Mobile/Desktop) a partir de File
  Future<String> uploadOrderImage(File imageFile, String orderId) async {
    try {
      // Validar tamanho do arquivo
      final fileSize = await imageFile.length();
      if (fileSize > SupabaseConfig.maxImageSize) {
        throw Exception('Imagem muito grande. Máximo: ${SupabaseConfig.maxImageSize ~/ (1024 * 1024)}MB');
      }

      // Validar tipo do arquivo
      final extension = path.extension(imageFile.path).toLowerCase();
      if (!SupabaseConfig.allowedImageTypes.contains(extension.replaceAll('.', ''))) {
        throw Exception('Tipo de arquivo não suportado');
      }

      // Gerar nome único para o arquivo
      final fileName = '${_uuid.v4()}$extension';
      final filePath = 'orders/$orderId/$fileName';

      // Upload para o Supabase Storage (arquivo)
      await _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .upload(filePath, imageFile);

      // URL pública
      final publicUrl = _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (error) {
      throw Exception('Erro ao fazer upload da imagem: $error');
    }
  }

  // Upload (Web) a partir de bytes
  Future<String> uploadOrderImageBytes(Uint8List bytes, String orderId, {String? originalName}) async {
    try {
      // Validar tamanho
      final fileSize = bytes.lengthInBytes;
      if (fileSize > SupabaseConfig.maxImageSize) {
        throw Exception('Imagem muito grande. Máximo: ${SupabaseConfig.maxImageSize ~/ (1024 * 1024)}MB');
      }

      // Inferir extensão a partir do nome original (fallback .jpg)
      String extension = '.jpg';
      if (originalName != null && originalName.contains('.')) {
        extension = originalName.substring(originalName.lastIndexOf('.'));
      }
      var extNoDot = extension.replaceAll('.', '').toLowerCase();
      if (!SupabaseConfig.allowedImageTypes.contains(extNoDot)) {
        extension = '.jpg';
        extNoDot = 'jpg';
      }

      final fileName = '${_uuid.v4()}$extension';
      final filePath = 'orders/$orderId/$fileName';

      // Upload binário (Web)
      await _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$extNoDot'),
          );

      final publicUrl = _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (error) {
      throw Exception('Erro ao fazer upload da imagem (web): $error');
    }
  }

  // Upload múltiplo (Mobile/Desktop)
  Future<List<String>> uploadOrderImages(List<File> imageFiles, String orderId) async {
    final List<String> uploadedUrls = [];
    for (final imageFile in imageFiles) {
      try {
        final url = await uploadOrderImage(imageFile, orderId);
        uploadedUrls.add(url);
      } catch (error) {
        // ignore: avoid_print
        print('Erro ao fazer upload de uma imagem: $error');
      }
    }
    return uploadedUrls;
  }

  // Upload múltiplo (Web)
  Future<List<String>> uploadOrderImagesBytes(List<Uint8List> imagesBytes, String orderId, {List<String?>? originalNames}) async {
    final List<String> uploadedUrls = [];
    for (var i = 0; i < imagesBytes.length; i++) {
      try {
        final name = (originalNames != null && i < originalNames.length) ? originalNames[i] : null;
        final url = await uploadOrderImageBytes(imagesBytes[i], orderId, originalName: name);
        uploadedUrls.add(url);
      } catch (error) {
        // ignore: avoid_print
        print('Erro ao fazer upload de uma imagem (web): $error');
      }
    }
    return uploadedUrls;
  }

  Future<void> deleteOrderImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.imagesBucket);

      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage
            .from(SupabaseConfig.imagesBucket)
            .remove([filePath]);
      }
    } catch (error) {
      throw Exception('Erro ao deletar imagem: $error');
    }
  }

  Future<List<String>> deleteOrderImages(List<String> imageUrls) async {
    final List<String> deletedUrls = [];
    for (final imageUrl in imageUrls) {
      try {
        await deleteOrderImage(imageUrl);
        deletedUrls.add(imageUrl);
      } catch (error) {
        // ignore: avoid_print
        print('Erro ao deletar imagem: $error');
      }
    }
    return deletedUrls;
  }

}

// Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});
