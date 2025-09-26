import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/orders_service.dart';
import '../../core/clients_service.dart';
import '../../core/pdf_service.dart';
import '../../core/company_profile_service.dart';

class OrderPdfPreviewScreen extends ConsumerStatefulWidget {
  final ServiceOrder order;
  const OrderPdfPreviewScreen({super.key, required this.order});

  @override
  ConsumerState<OrderPdfPreviewScreen> createState() => _OrderPdfPreviewScreenState();
}

class _OrderPdfPreviewScreenState extends ConsumerState<OrderPdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final clientsService = ref.read(clientsServiceProvider);
      final ordersService = ref.read(ordersServiceProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final companyService = ref.read(companyProfileServiceProvider);

      Client? client;
      if (widget.order.clientId != null) {
        try { client = await clientsService.getClientById(widget.order.clientId!); } catch (_) {}
      }
      final items = await ordersService.getOrderItems(widget.order.id);
      final profile = await companyService.getProfile();

      final pdfBytes = await pdfService.buildOrderPdf(order: widget.order, client: client, items: items, profile: profile);
      if (!mounted) return;
      setState(() {
        _pdfBytes = pdfBytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    final fileName = '${widget.order.orderNumber}.pdf';
    // Para Web e Mobile/Desktop, o Printing.sharePdf aciona o download/compartilhar nativo
    await Printing.sharePdf(bytes: _pdfBytes!, filename: fileName);
  }

  Future<void> _shareWhatsApp() async {
    if (_pdfBytes == null) return;
    final text = Uri.encodeComponent('Ordem ${widget.order.orderNumber}');
    final url = Uri.parse('https://wa.me/?text=$text');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF ${widget.order.orderNumber}'),
        actions: [
          IconButton(onPressed: _pdfBytes == null ? null : _downloadPdf, icon: const Icon(Icons.download)),
          IconButton(onPressed: _pdfBytes == null ? null : _shareWhatsApp, icon: const Icon(Icons.share)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pdfBytes == null
              ? const Center(child: Text('Falha ao gerar PDF'))
              : PdfPreview(
                  build: (format) async => _pdfBytes!,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                ),
    );
  }
}
