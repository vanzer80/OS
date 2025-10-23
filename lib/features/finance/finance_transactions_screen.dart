import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/finance_service.dart';

class FinanceTransactionsScreen extends ConsumerStatefulWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  ConsumerState<FinanceTransactionsScreen> createState() =>
      _FinanceTransactionsScreenState();
}

class _FinanceTransactionsScreenState
    extends ConsumerState<FinanceTransactionsScreen> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filtro por período',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 1),
                initialDateRange: _range,
              );
              if (picked != null) {
                setState(() => _range = picked);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<LedgerItem>>(
        future: ref
            .read(financeServiceProvider)
            .getLedger(start: _range?.start, end: _range?.end),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Sem transações no período.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final it = items[index];
              final isIncome = it.type == 'income';
              final color = isIncome ? Colors.green : Colors.redAccent;
              final sign = isIncome ? '+' : '-';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    isIncome ? Icons.call_received : Icons.call_made,
                    color: color,
                  ),
                ),
                title: Text(it.description),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(it.entryDate)),
                trailing: Text(
                  '$sign ${currency.format(it.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
