import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'orders_service.dart';
import 'clients_service.dart';
import 'company_profile_service.dart';

class PdfService {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  Future<Uint8List> buildOrderPdf({
    required ServiceOrder order,
    required Client? client,
    required List<OrderItem> items,
    required CompanyProfile? profile,
  }) async {
    final pdf = pw.Document();

    final total = items.fold<double>(0.0, (sum, it) => sum + it.totalPrice);
    final totalServicos = total; // alias para clareza

    String titlePrefix;
    switch (order.type) {
      case OrderType.budget:
        titlePrefix = 'ORÇAMENTO';
        break;
      case OrderType.service:
        titlePrefix = 'OS';
        break;
      case OrderType.sale:
        titlePrefix = 'VENDA';
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header empresa
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(profile?.name ?? 'Minha Oficina', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  if ((profile?.taxId ?? '').isNotEmpty) pw.Text(profile!.taxId!),
                  if ((profile?.addressLine ?? '').isNotEmpty) pw.Text(profile!.addressLine!),
                  if (((profile?.zip ?? '').isNotEmpty) || ((profile?.city ?? '').isNotEmpty))
                    pw.Text('${profile?.zip ?? ''} - ${profile?.city ?? ''}/${profile?.state ?? ''}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if ((profile?.phone ?? '').isNotEmpty) pw.Text('Tel.: ${profile!.phone!}'),
                  if ((profile?.email ?? '').isNotEmpty) pw.Text(profile!.email!),
                  if ((profile?.contactName ?? '').isNotEmpty) pw.Text('Contato: ${profile!.contactName!}'),
                  pw.Text(_dateFmt.format(order.createdAt)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          // Faixa título com número
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey600,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Center(
              child: pw.Text('$titlePrefix ${order.orderNumber}',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
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
                pw.Text('Equipamento', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Marca', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Modelo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Nº Série', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order.equipment ?? '-')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order.brand ?? '-')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order.model ?? '-')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order.serialNumber ?? '-')),
                    ]),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // Itens
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(5), // Nome
              1: const pw.FlexColumnWidth(1), // Quantidade
              2: const pw.FlexColumnWidth(1), // Unidade
              3: const pw.FlexColumnWidth(2), // Unit
              4: const pw.FlexColumnWidth(2), // Total
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Descrição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qtd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...items.map((it) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.description)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.quantity.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.unit)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currency.format(it.unitPrice))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_currency.format(it.totalPrice))),
                    ],
                  )),
            ],
          ),

          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Total Serviços  ${_currency.format(totalServicos)}'),
                pw.SizedBox(height: 4),
                pw.Text('Subtotal        ${_currency.format(totalServicos)}'),
                pw.SizedBox(height: 6),
                pw.Text('Total ${titlePrefix}    ${_currency.format(totalServicos)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),

          pw.SizedBox(height: 12),
          if ((order.observations ?? order.description ?? '').isNotEmpty) ...[
            pw.Text('Observações', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(order.observations ?? order.description ?? ''),
          ],

          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(text: 'Condições de Pagamento: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: order.paymentTerms ?? '—'),
                  ]),
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(text: 'Garantia: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: order.warranty ?? '—'),
                  ]),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Column(children: [
              if ((profile?.signatureUrl ?? '').isNotEmpty)
                pw.Container(height: 40),
              pw.Text(profile?.name ?? 'Oficina', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if ((profile?.contactName ?? '').isNotEmpty) pw.Text(profile!.contactName!),
            ]),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
