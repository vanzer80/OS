import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  UpdateService({required this.versionJsonUrl});

  final String versionJsonUrl;

  Future<void> checkForUpdates(BuildContext context, {bool silent = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final localCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final uri = Uri.parse(versionJsonUrl);
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        if (!silent && context.mounted) _showSnack(context, 'Não foi possível verificar atualização (${resp.statusCode}).');
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final remoteCode = (data['versionCode'] as num?)?.toInt() ?? 0;
      final remoteName = data['versionName'] as String? ?? '';
      final apkUrl = data['apkUrl'] as String?;
      final changelog = data['changelog'] as String? ?? '';

      if (remoteCode > localCode && apkUrl != null && apkUrl.isNotEmpty) {
        if (context.mounted) _showUpdateDialog(context, remoteName, changelog, apkUrl);
      } else if (!silent) {
        if (context.mounted) _showSnack(context, 'Você já está na última versão (${packageInfo.version}).');
      }
    } catch (e) {
      if (!silent && context.mounted) _showSnack(context, 'Falha ao verificar atualização: $e');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showUpdateDialog(BuildContext context, String versionName, String changelog, String apkUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova versão disponível ($versionName)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uma nova atualização está disponível para download.'),
            if (changelog.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Mudanças:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(changelog),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.system_update_alt),
            label: const Text('Baixar atualização'),
          ),
        ],
      ),
    );
  }
}
