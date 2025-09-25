import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

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

      // Upload para o Supabase Storage
      await _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .upload(filePath, imageFile);

      // Retornar URL pública da imagem
      final publicUrl = _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (error) {
      throw Exception('Erro ao fazer upload da imagem: $error');
    }
  }

  Future<List<String>> uploadOrderImages(List<File> imageFiles, String orderId) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      try {
        final url = await uploadOrderImage(imageFile, orderId);
        uploadedUrls.add(url);
      } catch (error) {
        // Log error mas continua com outras imagens
        print('Erro ao fazer upload de uma imagem: $error');
      }
    }

    return uploadedUrls;
  }

  Future<void> deleteOrderImage(String imageUrl) async {
    try {
      // Extrair o caminho do arquivo da URL
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
