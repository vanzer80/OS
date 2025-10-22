import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart'
    show Printing, PdfPreview; // adiciona visualização e compartilhamento
import '../../core/clients_service.dart';
import '../../core/company_profile_service.dart';
import '../../core/orders_service.dart';
import '../../core/payments_service.dart';
import '../../core/receipt_pdf_service.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

class ReceiptPdfPreviewScreen extends ConsumerStatefulWidget {
  final ServiceOrder order;
  const ReceiptPdfPreviewScreen({super.key, required this.order});

  @override
  ConsumerState<ReceiptPdfPreviewScreen> createState() => _ReceiptPdfPreviewScreenState();
}

class _ReceiptPdfPreviewScreenState extends ConsumerState<ReceiptPdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clientsService = ref.read(clientsServiceProvider);
      final companyService = ref.read(companyProfileServiceProvider);
      final paymentsService = ref.read(paymentsServiceProvider);
      final receiptPdfService = ref.read(receiptPdfServiceProvider);

      final clientId = widget.order.clientId;
      if (clientId == null) {
        throw Exception('Ordem sem cliente associado');
      }
      final client = await clientsService.getClientById(clientId);
      final company = await companyService.getProfile() ??
          CompanyProfile(userId: '', name: 'Empresa', phone: null);
      final payments = await paymentsService.getPaymentsByOrder(widget.order.id);

      final pdfBytes = await receiptPdfService.buildReceiptPdf(
        company: company,
        client: client,
        order: widget.order,
        payments: payments,
      );

      setState(() {
        _pdfBytes = pdfBytes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    final fileName = 'recibo_${widget.order.orderNumber}.pdf';
    await Printing.sharePdf(bytes: _pdfBytes!, filename: fileName);
  }

  Future<void> _shareGeneric() async {
    if (_pdfBytes == null) return;
    final fileName = 'recibo_${widget.order.orderNumber}.pdf';
    try {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao compartilhar: $e')),
      );
    }
  }

  Future<void> _shareWhatsApp() async {
    try {
      final text = Uri.encodeComponent('Recibo da Ordem ${widget.order.orderNumber}');
      final url = Uri.parse('https://wa.me/?text=$text');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir WhatsApp: $e')),
      );
    }
  }

  Future<void> _shareEmail() async {
    try {
      final subject = Uri.encodeComponent('Recibo ${widget.order.orderNumber}');
      final body = Uri.encodeComponent('Segue o recibo em anexo. Caso não abra, use o botão Baixar/Compartilhar para salvar o PDF.');
      final uri = Uri.parse('mailto:?subject=$subject&body=$body');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir Email: $e')),
      );
    }
  }

  void _openShareSheet() {
    if (_pdfBytes == null) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartilhar (PDF)'),
              subtitle: const Text('Usa compartilhamento nativo com o arquivo PDF'),
              onTap: () {
                Navigator.pop(context);
                _shareGeneric();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: const Text('Abre o cliente de email para enviar o recibo'),
              onTap: () {
                Navigator.pop(context);
                _shareEmail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp'),
              subtitle: const Text('Abre o WhatsApp Web/App com mensagem'),
              onTap: () {
                Navigator.pop(context);
                _shareWhatsApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pré-visualização do Recibo'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'Baixar/Compartilhar',
            icon: const Icon(Icons.download),
            onPressed: _pdfBytes == null ? null : _downloadPdf,
          ),
          IconButton(
            tooltip: 'Compartilhar',
            icon: const Icon(Icons.share),
            onPressed: _pdfBytes == null ? null : _openShareSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro ao gerar recibo: $_error'))
              : _pdfBytes == null
                  ? const Center(child: Text('PDF não disponível'))
                  : PdfPreview(
                      build: (format) async => _pdfBytes!,
                      allowSharing: true,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                    ),
    );
  }
}