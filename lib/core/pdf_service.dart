import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'orders_service.dart';
import 'clients_service.dart';

class PdfService {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  Future<Uint8List> buildOrderPdf({
    required ServiceOrder order,
    required Client? client,
    required List<OrderItem> items,
  }) async {
    final pdf = pw.Document();

    final total = items.fold<double>(0.0, (sum, it) => sum + it.totalPrice);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ordem ${order.orderNumber}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text(_dateFmt.format(order.createdAt)),
              ],
            ),
          ),

          // Dados do Cliente
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Cliente', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(client?.name ?? '-'),
                if ((client?.phone ?? '').isNotEmpty) pw.Text(client!.phone!),
                if ((client?.email ?? '').isNotEmpty) pw.Text(client!.email!),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // Dados do Equipamento
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Dados do Equipamento', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                if ((order.equipment ?? '').isNotEmpty) pw.Text('Equipamento: ${order.equipment}'),
                if ((order.model ?? '').isNotEmpty) pw.Text('Modelo: ${order.model}'),
                if ((order.brand ?? '').isNotEmpty) pw.Text('Marca: ${order.brand}'),
                if ((order.serialNumber ?? '').isNotEmpty) pw.Text('S/N: ${order.serialNumber}'),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // Itens
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Descrição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qtd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...items.map((it) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.description)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.quantity.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currency.format(it.unitPrice))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currency.format(it.totalPrice))),
                    ],
                  )),
            ],
          ),

          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text('Total: ${_currency.format(total)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              )
            ],
          ),

          if ((order.description ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Descrição do Serviço', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(order.description!),
          ],
        ],
      ),
    );

    return pdf.save();
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
