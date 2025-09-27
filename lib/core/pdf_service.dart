import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
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

    String joinParts(List<String?> parts) =>
        parts.where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim()).join(', ');
    final lineAddress1 = joinParts([profile?.street, profile?.streetNumber, profile?.neighborhood]);
    final lineAddress2 = joinParts([profile?.city, profile?.state, profile?.zip]);

    // Pré-carregar logo (opcional)
    pw.ImageProvider? logoImage;
    if ((profile?.logoUrl ?? '').isNotEmpty) {
      try {
        logoImage = await networkImage(profile!.logoUrl!);
      } catch (_) {
        logoImage = null;
      }
    }

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
          // Cabeçalho empresa (modelo)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Image(logoImage, height: 36),
                    ),

                  pw.Text(
                    profile?.name ?? 'Oficina',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  if ((profile?.taxId ?? '').isNotEmpty)
                    pw.Text(profile!.taxId!, style: const pw.TextStyle(fontSize: 10)),
                  if (lineAddress1.isNotEmpty)
                    pw.Text(lineAddress1, style: const pw.TextStyle(fontSize: 10)),
                  if (lineAddress2.isNotEmpty)
                    pw.Text(lineAddress2, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if ((profile?.phone ?? '').isNotEmpty)
                    pw.Text('Tel.: ${profile!.phone!}', style: const pw.TextStyle(fontSize: 10)),
                  if ((profile?.email ?? '').isNotEmpty)
                    pw.Text(profile!.email!, style: const pw.TextStyle(fontSize: 10)),
                  if ((profile?.contactName ?? '').isNotEmpty)
                    pw.Text('Contato: ${profile!.contactName!}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 6),
          // Linha "Dados do Cliente" + Data à direita
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Dados do Cliente', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Data: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey500, thickness: 1),
          pw.SizedBox(height: 6),

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
