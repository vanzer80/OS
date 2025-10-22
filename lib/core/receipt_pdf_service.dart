import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'company_profile_service.dart';
import 'clients_service.dart';
import 'orders_service.dart';
import 'payments_service.dart';

class ReceiptPdfService {
  Future<Uint8List> buildReceiptPdf({
    required CompanyProfile company,
    required Client client,
    required ServiceOrder order,
    List<Payment>? payments,
  }) async {
    final pdf = pw.Document();
    final amount = _resolveAmount(order, payments);
    final paymentMethod = payments != null && payments.isNotEmpty ? payments.first.method : null;

    final titleStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final labelStyle = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final textStyle = pw.TextStyle(fontSize: 11);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        ),
        build: (context) => [
          _header(company, titleStyle, textStyle),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Recibo', style: titleStyle),
                    pw.Text('OS ${order.orderNumber}', style: labelStyle),
                  ],
                ),
                pw.SizedBox(height: 10),
                _keyValue('Cliente', client.name, labelStyle),
                _keyValue('Documento', client.document ?? '-', labelStyle),
                _keyValue('Contato', client.phone ?? '-', labelStyle),
                pw.SizedBox(height: 10),
                _keyValue('Valor', _formatCurrency(amount), labelStyle),
                if (paymentMethod != null)
                  _keyValue('Pagamento', paymentMethod.toUpperCase(), labelStyle),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Recebemos de ${client.name} a quantia de ${_formatCurrency(amount)} referente à ${_orderContext(order)}.',
                  style: textStyle,
                ),
                if (order.description?.isNotEmpty == true) ...[
                  pw.SizedBox(height: 6),
                  pw.Text('Observação: ${order.description}', style: textStyle),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          _signatureBlock(company, labelStyle, textStyle),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(_formatDate(DateTime.now()), style: textStyle),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(CompanyProfile company, pw.TextStyle titleStyle, pw.TextStyle textStyle) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(company.name, style: titleStyle),
              if ((company.taxId ?? '').isNotEmpty)
                pw.Text('CNPJ/CPF: ${company.taxId}', style: textStyle),
              if (_composeAddress(company).isNotEmpty)
                pw.Text(_composeAddress(company), style: textStyle),
              if ((company.phone ?? '').isNotEmpty)
                pw.Text('Tel: ${company.phone}', style: textStyle),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _keyValue(String label, String value, pw.TextStyle labelStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(width: 120, child: pw.Text(label, style: labelStyle)),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  String _composeAddress(CompanyProfile c) {
    final parts = <String>[];
    if ((c.addressLine ?? '').isNotEmpty) parts.add(c.addressLine!);
    final street = [c.street, c.streetNumber].where((e) => (e ?? '').isNotEmpty).join(', ');
    if (street.isNotEmpty) parts.add(street);
    final cityState = [c.city, c.state].where((e) => (e ?? '').isNotEmpty).join('/');
    if (cityState.isNotEmpty) parts.add(cityState);
    if ((c.neighborhood ?? '').isNotEmpty) parts.add(c.neighborhood!);
    if ((c.zip ?? '').isNotEmpty) parts.add('CEP ${c.zip}');
    return parts.join(' • ');
  }

  pw.Widget _signatureBlock(CompanyProfile company, pw.TextStyle labelStyle, pw.TextStyle textStyle) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.SizedBox(height: 28),
              pw.Container(height: 1, color: PdfColors.grey600),
              pw.SizedBox(height: 4),
              pw.Text(company.name, style: labelStyle),
              pw.Text('Assinatura', style: textStyle.copyWith(color: PdfColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }

  String _orderContext(ServiceOrder order) {
    final parts = <String>[];
    if (order.equipment?.isNotEmpty == true) parts.add(order.equipment!);
    if (order.brand?.isNotEmpty == true) parts.add(order.brand!);
    if (order.model?.isNotEmpty == true) parts.add(order.model!);
    return parts.isEmpty ? 'serviço prestado' : 'serviço em ${parts.join(' ')}';
  }

  double _resolveAmount(ServiceOrder order, List<Payment>? payments) {
    if (payments != null && payments.isNotEmpty) {
      return payments.first.amount;
    }
    // Fallback: usa total da ordem
    return order.totalAmount;
  }

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return f.format(value);
  }

  String _formatDate(DateTime date) {
    final f = DateFormat('dd/MM/yyyy');
    return f.format(date);
  }
}

final receiptPdfServiceProvider = Provider<ReceiptPdfService>((ref) => ReceiptPdfService());