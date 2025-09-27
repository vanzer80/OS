import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/orders_service.dart';
import '../../core/clients_service.dart';
import '../../core/pdf_service.dart';
import '../../core/company_profile_service.dart';
import 'order_pdf_preview_screen.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final ServiceOrder order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Client? _client;
  List<OrderItem> _items = const [];
  bool _loading = true;
  Uint8List? _pdf;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final clientsSvc = ref.read(clientsServiceProvider);
      final ordersSvc = ref.read(ordersServiceProvider);
      final pdfSvc = ref.read(pdfServiceProvider);
      final companySvc = ref.read(companyProfileServiceProvider);

      Client? client;
      if (widget.order.clientId != null) {
        try { client = await clientsSvc.getClientById(widget.order.clientId!); } catch (_) {}
      }
      final items = await ordersSvc.getOrderItems(widget.order.id);
      final imageRecords = await ordersSvc.getOrderImages(widget.order.id);
      final profile = await companySvc.getProfile();
      final pdf = await pdfSvc.buildOrderPdf(order: widget.order, client: client, items: items, profile: profile, imageUrls: const [], imageRecords: imageRecords);

      if (!mounted) return;
      setState(() {
        _client = client;
        _items = items;
        _pdf = pdf;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar ordem: $e')));
    }
  }

  Future<void> _shareWhatsApp() async {
    final text = Uri.encodeComponent('Ordem ${widget.order.orderNumber}');
    final url = Uri.parse('https://wa.me/?text=$text');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadPdf() async {
    if (_pdf == null) return;
    await Printing.sharePdf(bytes: _pdf!, filename: '${widget.order.orderNumber}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ordem ${order.orderNumber}'),
        actions: [
          IconButton(
            tooltip: 'Visualizar PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _pdf == null ? null : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderPdfPreviewScreen(order: order),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Baixar/Compartilhar',
            icon: const Icon(Icons.download),
            onPressed: _pdf == null ? null : _downloadPdf,
          ),
          IconButton(
            tooltip: 'WhatsApp',
            icon: const Icon(Icons.share),
            onPressed: _shareWhatsApp,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status e tipo
                Row(
                  children: [
                    Chip(label: Text(order.type == OrderType.service ? 'Serviço' : order.type == OrderType.budget ? 'Orçamento' : 'Venda')),
                    const SizedBox(width: 8),
                    Chip(label: Text(order.status == OrderStatus.pending ? 'Pendente' : order.status == OrderStatus.inProgress ? 'Em Andamento' : order.status == OrderStatus.completed ? 'Concluída' : 'Cancelada')),
                    const Spacer(),
                    Text('R\$ ${order.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),

                // Cliente
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Cliente'),
                    subtitle: Text(_client?.name ?? '-'),
                  ),
                ),
                const SizedBox(height: 8),

                // Equipamento
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dados do Equipamento', style: TextStyle(fontWeight: FontWeight.bold)),
                        if ((order.equipment ?? '').isNotEmpty) Text('Equipamento: ${order.equipment}'),
                        if ((order.model ?? '').isNotEmpty) Text('Modelo: ${order.model}'),
                        if ((order.brand ?? '').isNotEmpty) Text('Marca: ${order.brand}'),
                        if ((order.serialNumber ?? '').isNotEmpty) Text('S/N: ${order.serialNumber}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Itens
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        leading: Icon(Icons.list),
                        title: Text('Itens da Ordem'),
                      ),
                      const Divider(height: 1),
                      ..._items.map((it) => ListTile(
                            title: Text(it.description),
                            subtitle: Text('Qtd ${it.quantity}  •  Unit R\$ ${it.unitPrice.toStringAsFixed(2)}'),
                            trailing: Text('R\$ ${it.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                if ((order.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Descrição do Serviço'),
                      subtitle: Text(order.description!),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Ações grandes
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pdf == null ? null : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OrderPdfPreviewScreen(order: order),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Visualizar PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pdf == null ? null : _downloadPdf,
                        icon: const Icon(Icons.download),
                        label: const Text('Baixar/Compartilhar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareWhatsApp,
                        icon: const Icon(Icons.share),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
