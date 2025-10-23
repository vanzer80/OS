import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    List<String> imageUrls = const [],
    List<OrderImageRecord> imageRecords = const [],
  }) async {
    // Fonts: NotoSans with fallback to cover Unicode (e.g., em dash)
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      fontFallback: [baseFont],
    );
    final pdf = pw.Document(theme: theme);

    final total = items.fold<double>(0.0, (sum, it) => sum + it.totalPrice);
    final totalServicos = total; // alias para clareza

    String joinParts(List<String?> parts) => parts
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .join(', ');
    final lineAddress1 = joinParts([
      profile?.street,
      profile?.streetNumber,
      profile?.neighborhood,
    ]);
    final lineAddress2 = joinParts([
      profile?.city,
      profile?.state,
      profile?.zip,
    ]);

    // Pré-carregar logo (opcional)
    pw.ImageProvider? logoImage;
    if ((profile?.logoUrl ?? '').isNotEmpty) {
      try {
        final bucket = CompanyProfileService.bucket;
        final urlOrPath = profile!.logoUrl!;
        final isUrl = urlOrPath.startsWith('http');
        String path;
        if (isUrl) {
          try {
            final uri = Uri.parse(urlOrPath);
            final idx = uri.pathSegments.indexOf(bucket);
            path = idx != -1 && idx + 1 < uri.pathSegments.length
                ? uri.pathSegments.sublist(idx + 1).join('/')
                : urlOrPath;
          } catch (_) {
            path = urlOrPath;
          }
        } else {
          path = urlOrPath;
        }
        final signed = await Supabase.instance.client.storage
            .from(bucket)
            .createSignedUrl(path, 60 * 60);
        logoImage = await networkImage(signed);
      } catch (_) {
        logoImage = null;
      }
    }

    // Pré-carregar assinatura (opcional)
    pw.ImageProvider? signatureImage;
    if ((profile?.signatureUrl ?? '').isNotEmpty) {
      try {
        final bucket = CompanyProfileService.bucket;
        final urlOrPath = profile!.signatureUrl!;
        final isUrl = urlOrPath.startsWith('http');
        String path;
        if (isUrl) {
          try {
            final uri = Uri.parse(urlOrPath);
            final idx = uri.pathSegments.indexOf(bucket);
            path = idx != -1 && idx + 1 < uri.pathSegments.length
                ? uri.pathSegments.sublist(idx + 1).join('/')
                : urlOrPath;
          } catch (_) {
            path = urlOrPath;
          }
        } else {
          path = urlOrPath;
        }
        final signed = await Supabase.instance.client.storage
            .from(bucket)
            .createSignedUrl(path, 60 * 60);
        signatureImage = await networkImage(signed);
      } catch (_) {
        signatureImage = null;
      }
    }

    // Pré-carregar imagens da ordem (máx 5)
    final List<({pw.ImageProvider img, String? title, String? desc})>
    orderImages = [];
    if (imageRecords.isNotEmpty) {
      for (final rec in imageRecords.take(5)) {
        try {
          final img = await networkImage(rec.url);
          orderImages.add((img: img, title: rec.title, desc: rec.description));
        } catch (_) {}
      }
    } else {
      for (final url in imageUrls.take(5)) {
        try {
          final img = await networkImage(url);
          orderImages.add((img: img, title: null, desc: null));
        } catch (_) {}
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
                    pw.Container(
                      width: 48,
                      height: 36,
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.FittedBox(
                        fit: pw.BoxFit.contain,
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Image(logoImage),
                      ),
                    ),

                  pw.Text(
                    profile?.name ?? 'Oficina',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if ((profile?.taxId ?? '').isNotEmpty)
                    pw.Text(
                      profile!.taxId!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (lineAddress1.isNotEmpty)
                    pw.Text(
                      lineAddress1,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (lineAddress2.isNotEmpty)
                    pw.Text(
                      lineAddress2,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if ((profile?.phone ?? '').isNotEmpty)
                    pw.Text(
                      'Tel.: ${profile!.phone!}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if ((profile?.email ?? '').isNotEmpty)
                    pw.Text(
                      profile!.email!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if ((profile?.contactName ?? '').isNotEmpty)
                    pw.Text(
                      'Contato: ${profile!.contactName!}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 6),
          // Linha "Dados do Cliente" + Data à direita
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dados do Cliente',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Data: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey500, thickness: 1),
          pw.SizedBox(height: 6),

          // Informações do Cliente (sem moldura)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if ((client?.name ?? '').isNotEmpty)
                pw.Text(client!.name, style: const pw.TextStyle(fontSize: 12)),
              if ((client?.phone ?? '').isNotEmpty)
                pw.Text(
                  client!.phone!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if ((client?.email ?? '').isNotEmpty)
                pw.Text(
                  client!.email!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Faixa título com número (agora após cliente)
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey600,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Center(
              child: pw.Text(
                '$titlePrefix Nº ${order.orderNumber}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),

          pw.SizedBox(height: 8),

          // Dados do Equipamento (sem moldura)
          pw.Text(
            'Equipamento',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
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
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Tipo',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Marca',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Modelo',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Nº Série',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order.equipment ?? '-'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order.brand ?? '-'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order.model ?? '-'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order.serialNumber ?? '-'),
                  ),
                ],
              ),
            ],
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
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Descrição',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Qtd',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Unid',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Unit',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...items.map(
                (it) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.description),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.quantity.toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(it.unit),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_currency.format(it.unitPrice)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_currency.format(it.totalPrice)),
                    ),
                  ],
                ),
              ),
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
                pw.Text(
                  'Total $titlePrefix    ${_currency.format(totalServicos)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),
          if ((order.observations ?? order.description ?? '').isNotEmpty) ...[
            pw.Text(
              'Observações',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(order.observations ?? order.description ?? ''),
          ],

          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Condições de Pagamento: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text:
                            order.paymentTerms ??
                            (profile?.defaultPaymentTerms ?? '—'),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Garantia: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text:
                            order.warranty ?? (profile?.defaultWarranty ?? '—'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Seção de Fotos no final, antes da assinatura
          if (orderImages.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey500, thickness: 1),
            pw.SizedBox(height: 6),
            pw.Text(
              'Fotos',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
              },
              children: [
                for (var i = 0; i < orderImages.length; i += 3)
                  pw.TableRow(
                    children: [
                      for (var j = 0; j < 3; j++)
                        if (i + j < orderImages.length)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                              bottom: 10,
                              right: 7,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  height: 120,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: PdfColors.grey300,
                                    ),
                                  ),
                                  child: pw.FittedBox(
                                    child: pw.Image(orderImages[i + j].img),
                                  ),
                                ),
                                if (((orderImages[i + j].title) ?? '')
                                    .isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 4),
                                    child: pw.Text(
                                      orderImages[i + j].title!,
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (((orderImages[i + j].desc) ?? '')
                                    .isNotEmpty)
                                  pw.Text(
                                    orderImages[i + j].desc!,
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                              ],
                            ),
                          )
                        else
                          pw.Container(),
                    ],
                  ),
              ],
            ),
          ],

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Column(
              children: [
                if (signatureImage != null)
                  pw.Image(signatureImage, height: 40),
                pw.Text(
                  profile?.name ?? 'Oficina',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                if ((profile?.contactName ?? '').isNotEmpty)
                  pw.Text(profile!.contactName!),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
