import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/update_service.dart';
import '../../core/clients_service.dart';
import '../../core/orders_service.dart';
import '../../core/payments_service.dart';
import '../../core/filters_service.dart';
import '../../core/status_policy_service.dart';
import '../clients/add_client_screen.dart';
import '../orders/add_order_screen.dart';
import '../orders/edit_order_screen.dart';
import '../orders/order_details_screen.dart';
import '../profile/company_profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const ClientsTab(),
    const OrdersTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Assinar mudanças na tabela payments e manter gráficos sincronizados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = ref.read(paymentsServiceProvider);
      svc.subscribePaymentsRealtime(() {
        ref.refresh(monthlyRevenueProvider);
        ref.refresh(statusBreakdownProvider);
        ref.refresh(dashboardSummaryProvider);
      });
      // Assinar mudanças em service_orders para manter resumo e status atualizados
      final ordersSvc = ref.read(ordersServiceProvider);
      ordersSvc.subscribeOrdersRealtime(() {
        ref.refresh(dashboardSummaryProvider);
        ref.refresh(statusBreakdownProvider);
      });
    });
  }

  @override
  void dispose() {
    // Encerrar assinatura de pagamentos
    try {
      ref.read(paymentsServiceProvider).disposePaymentsRealtime();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Ordens',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _SkeletonSummaryCard extends StatelessWidget {
  const _SkeletonSummaryCard();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(40);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(width: 48, height: 20, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 100, height: 14, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: const Text('OS Express'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update_alt_outlined),
            tooltip: 'Verificar atualização',
            onPressed: () {
              UpdateService(
                versionJsonUrl: 'https://vanzer80.github.io/OS/version.json',
              ).checkForUpdates(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificações
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de resumo
            summaryAsync.when(
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Ordens Hoje',
                      value: s.ordersToday.toString(),
                      icon: Icons.today,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pendentes',
                      value: s.pending.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Row(
                children: const [
                  Expanded(child: _SkeletonSummaryCard()),
                  SizedBox(width: 16),
                  Expanded(child: _SkeletonSummaryCard()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Concluídas',
                      value: s.completed.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Faturamento',
                      value: currency.format(s.monthlyRevenue),
                      icon: Icons.attach_money,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                children: const [
                  Expanded(child: _SkeletonSummaryCard()),
                  SizedBox(width: 16),
                  Expanded(child: _SkeletonSummaryCard()),
                ],
              ),
              error: (e, _) => Row(
                children: const [
                  Expanded(child: _SkeletonSummaryCard()),
                  SizedBox(width: 16),
                  Expanded(child: _SkeletonSummaryCard()),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Ações rápidas
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'Nova Ordem',
                    subtitle: 'Criar ordem de serviço',
                    icon: Icons.add_circle,
                    color: Colors.blue,
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddOrderScreen(),
                        ),
                      );
                      if (result != null) {
                        ref.read(ordersProvider.notifier).loadOrders();
                        ref.refresh(dashboardSummaryProvider);
                        ref.refresh(statusBreakdownProvider);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Novo Cliente',
                    subtitle: 'Cadastrar cliente',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddClientScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'Orçamento',
                    subtitle: 'Criar orçamento',
                    icon: Icons.calculate,
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Navegar para novo orçamento
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Venda',
                    subtitle: 'Registrar venda',
                    icon: Icons.shopping_cart,
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navegar para nova venda
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'Gráficos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Distribuição de Status
            ref.watch(statusBreakdownProvider).when(
              data: (sb) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribuição por Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (sb.total == 0)
                        const Text('Sem ordens cadastradas.')
                      else ...[
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              if (sb.pending > 0)
                                Expanded(
                                  flex: sb.pending,
                                  child: Container(color: Colors.orange),
                                ),
                              if (sb.awaitingApproval > 0)
                                Expanded(
                                  flex: sb.awaitingApproval,
                                  child: Container(color: Colors.amber),
                                ),
                              if (sb.awaitingPayment > 0)
                                Expanded(
                                  flex: sb.awaitingPayment,
                                  child: Container(color: Colors.purple),
                                ),
                              if (sb.inProgress > 0)
                                Expanded(
                                  flex: sb.inProgress,
                                  child: Container(color: Colors.blue),
                                ),
                              if (sb.completed > 0)
                                Expanded(
                                  flex: sb.completed,
                                  child: Container(color: Colors.green),
                                ),

                              if (sb.cancelled > 0)
                                Expanded(
                                  flex: sb.cancelled,
                                  child: Container(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.orange))),
                                SizedBox(width: 6),
                                Text('Pendente'),
                              ],
                            ),
                            Text(': ${sb.pending}'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.amber))),
                                SizedBox(width: 6),
                                Text('Aguardando aprovação'),
                              ],
                            ),
                            Text(': ${sb.awaitingApproval}'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.purple))),
                                SizedBox(width: 6),
                                Text('Aguardando pagamento'),
                              ],
                            ),
                            Text(': ${sb.awaitingPayment}'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.blue))),
                                SizedBox(width: 6),
                                Text('Em andamento'),
                              ],
                            ),
                            Text(': ${sb.inProgress}'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.green))),
                                SizedBox(width: 6),
                                Text('Concluída'),
                              ],
                            ),
                            Text(': ${sb.completed}'),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(width: 12, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.red))),
                                SizedBox(width: 6),
                                Text('Cancelada'),
                              ],
                            ),
                            Text(': ${sb.cancelled}'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erro ao carregar status: $e'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Faturamento mensal
            ref.watch(monthlyRevenueProvider).when(
              data: (points) {
                final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
                final max = points
                    .map((p) => p.value)
                    .fold<double>(0.0, (prev, v) => v > prev ? v : prev);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Faturamento por Mês (últimos 12)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final p in points)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: max <= 0 ? 0 : 150 * (p.value / max),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final p in points)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    DateFormat('MM/yy').format(DateTime(p.year, p.month)),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Máximo: ${currency.format(max)}'),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erro ao carregar faturamento: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientsTab extends ConsumerStatefulWidget {
  const ClientsTab({super.key});

  @override
  ConsumerState<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends ConsumerState<ClientsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(clientsProvider.notifier).searchClients(query);
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(76),
              ),
            ),
          ),
        ),
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cliente encontrado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione seu primeiro cliente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(clientsProvider.notifier).loadClients();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        client.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      client.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (client.phone != null)
                          Text(client.phone!),
                        if (client.email != null)
                          Text(
                            client.email!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Editar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Excluir', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddClientScreen(client: client),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmar exclusão'),
                              content: Text('Deseja excluir o cliente ${client.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            ref.read(clientsProvider.notifier).deleteClient(client.id);
                          }
                        }
                      },
                    ),
                    onTap: () {
                      // TODO: Navegar para detalhes do cliente
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar clientes'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(clientsProvider.notifier).loadClients();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddClientScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  OrderType? _selectedType;
  OrderStatus? _selectedStatus;
  bool _showFilters = false;
  final _clientNameController = TextEditingController();
  String _clientNameQuery = '';

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    // Obter lista de clientes para mapear id->nome sem bloquear UI
    final clientsList = ref.watch(clientsProvider).maybeWhen(
      data: (c) => c,
      orElse: () => const <Client>[],
    );
    final Map<String, String> clientNameById = {
      for (final c in clientsList) c.id: c.name,
    };
    final filtersState = ref.watch(filtersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              try {
                final response = await Supabase.instance.client
                    .from('service_orders')
                    .select('count')
                    .count();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Conexão OK! Ordens no DB: $response')),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Erro: $error')),
                  );
                }
              }
            },
            tooltip: 'Testar Conexão DB',
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: _showFilters ? 'Ocultar Filtros' : 'Mostrar Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros Expansíveis
          if (_showFilters)
            _buildFiltersSection(),

          // Lista de Ordens
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                // Aplicar filtro local por nome do cliente (não altera backend)
                final lowerQuery = _clientNameQuery.trim().toLowerCase();
                final filtered = lowerQuery.isEmpty
                    ? orders
                    : orders.where((o) {
                        final name = clientNameById[o.clientId ?? '']?.toLowerCase() ?? '';
                        return name.contains(lowerQuery);
                      }).toList();
                if (orders.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: [
                    // Debug info
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Debug: ${filtered.length}/${orders.length} ordens (após filtro por cliente)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(child: _buildOrdersList(filtered, clientNameById)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddOrderScreen(),
            ),
          );
          if (result != null) {
            ref.read(ordersProvider.notifier).loadOrders(
              type: _selectedType,
              status: _selectedStatus,
            );
          }
        },
        label: const Text('Nova Ordem'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersSection() {
    final allowedStatusesAsync = ref.watch(allowedStatusesProvider);
    final List<OrderStatus> allowedStatusesList = allowedStatusesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => OrderStatus.values.toList(),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(76),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(filtersProvider.notifier).clearFilters();
                  setState(() {
                    _selectedType = null;
                    _selectedStatus = null;
                  });
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtro por nome do cliente
          TextField(
            controller: _clientNameController,
            onChanged: (value) {
              setState(() {
                _clientNameQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Filtrar por Cliente',
              hintText: 'Ex: João, Maria...',
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: _clientNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _clientNameController.clear();
                        setState(() => _clientNameQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),

          const SizedBox(height: 12),

          // Filtros em Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              // Tipo
              _buildFilterDropdown<OrderType>(
                label: 'Tipo',
                value: _selectedType,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...OrderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type == OrderType.service ? 'Serviços' :
                        type == OrderType.budget ? 'Orçamentos' : 'Vendas'
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),

              // Status
              _buildFilterDropdown<OrderStatus>(
                label: 'Status',
                value: _selectedStatus,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...allowedStatusesList.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusText(status)),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botão Aplicar Filtros
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(ordersProvider.notifier).loadOrders(
                  type: _selectedType,
                  status: _selectedStatus,
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Aplicar Filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          hint: Text(label),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma ordem encontrada',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira ordem de serviço',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ServiceOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a ordem ${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(ordersProvider.notifier).deleteOrder(order.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ordem ${order.orderNumber} excluída com sucesso!')),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir ordem: $error')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<ServiceOrder> orders, Map<String, String> clientNameById) {
    // Tornar o menu reativo às mudanças de política de status
    final allowedStatusesAsyncForMenu = ref.watch(allowedStatusesProvider);
    final List<OrderStatus> allowedForMenu = allowedStatusesAsyncForMenu.maybeWhen(
      data: (list) => list,
      orElse: () => OrderStatus.values.toList(),
    );
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(ordersProvider.notifier).loadOrders(
          type: _selectedType,
          status: _selectedStatus,
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final clientName = clientNameById[order.clientId ?? ''];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getOrderIcon(order.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                '${order.orderNumber} - ${order.type == OrderType.service ? 'Serviço' : order.type == OrderType.budget ? 'Orçamento' : 'Venda'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (clientName != null && clientName.isNotEmpty)
                    Text('Cliente: $clientName'),
                  if (order.equipment != null)
                    Text('Equipamento: ${order.equipment}'),
                  if (order.model != null)
                    Text('Modelo: ${order.model}'),
                  if (order.brand != null)
                    Text('Marca: ${order.brand}'),
                  if (order.serialNumber != null)
                    Text('S/N: ${order.serialNumber}'),
                  Text(
                    'R\$ ${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditOrderScreen(order: order),
                          ),
                        );
                        if (result != null) {
                          ref.read(ordersProvider.notifier).loadOrders(
                            type: _selectedType,
                            status: _selectedStatus,
                          );
                        }
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(order);
                      } else if (value.startsWith('status_')) {
                        final db = value.substring(7);
                        final target = OrderStatusDbX.fromDb(db);
                        final policy = ref.read(statusPolicyServiceProvider);
                        if (!policy.isTransitionAllowed(order.status, target)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Transição de '${_getStatusText(order.status)}' para '${_getStatusText(target)}' não permitida."),
                            ),
                          );
                          return;
                        }
                        try {
                          await ref.read(ordersProvider.notifier).updateOrderStatus(order.id, target);
                          // Atualiza gráficos
                          ref.refresh(statusBreakdownProvider);
                          ref.refresh(monthlyRevenueProvider);
                          ref.refresh(dashboardSummaryProvider);
                          // Atualiza políticas de status do menu
                          ref.refresh(allowedStatusesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Status da ordem atualizado.')),
                          );
                        } catch (e) {
                          // Em caso de violação de constraint, atualiza políticas e mostra mensagem amigável
                          ref.refresh(allowedStatusesProvider);
                          final msg = e.toString();
                          final friendly = msg.contains('[ERR_STATUS_CHECK_VIOLATION]')
                              ? 'O servidor rejeitou este status. Verifique as políticas/constraints e tente novamente.'
                              : msg;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Falha ao atualizar status: $friendly')),
                          );
                        }
                      } else if (value == 'mark_paid') {
                        final paymentsService = ref.read(paymentsServiceProvider);
                        try {
                          // Capturar observação do método (opcional)
                          final noteController = TextEditingController();
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Registrar Pagamento'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Confirme o registro de pagamento desta ordem.'),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: noteController,
                                    decoration: const InputDecoration(
                                      labelText: 'Observação do método (opcional)',
                                      hintText: 'Ex: PIX Banco X, Dinheiro, Cartão Y',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Confirmar'),
                                ),
                              ],
                            ),
                          ) ?? false;
                          if (!confirmed) return;

                          await paymentsService.createPayment(
                            orderId: order.id,
                            amount: order.totalAmount,
                            method: 'pix',
                            methodNote: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                          );
                          // Ao pagar, concluir a ordem automaticamente
                          await ref.read(ordersProvider.notifier).updateOrderStatus(order.id, OrderStatus.completed);
                          // Atualiza gráficos (status e faturamento)
                          ref.refresh(statusBreakdownProvider);
                          ref.refresh(monthlyRevenueProvider);
                          ref.refresh(dashboardSummaryProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pagamento registrado e ordem concluída.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Falha ao registrar pagamento: $e')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) {
                        final allowed = allowedForMenu;
                        final items = <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                        ];
                        for (final s in allowed) {
                          items.add(
                            PopupMenuItem(
                              value: 'status_${s.dbName}',
                              child: Row(
                                children: [
                                  Icon(_statusIconFor(s), size: 20),
                                  const SizedBox(width: 8),
                                  Text('Status: ${_getStatusText(s)}'),
                                ],
                              ),
                            ),
                          );
                        }
                        items.add(const PopupMenuDivider());
                        items.add(
                          const PopupMenuItem(
                            value: 'mark_paid',
                            child: Row(
                              children: [
                                Icon(Icons.monetization_on, size: 20),
                                SizedBox(width: 8),
                                Text('Registrar Pagamento'),
                              ],
                            ),
                          ),
                        );
                        return items;
                      },
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsScreen(order: order),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erro ao carregar ordens'),
          const SizedBox(height: 8),
          Text(error.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).loadOrders(
                type: _selectedType,
                status: _selectedStatus,
              );
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.awaitingApproval:
        return Colors.amber;
      case OrderStatus.awaitingPayment:
        return Colors.purple;
      case OrderStatus.awaitingPart:
        return Colors.brown;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.awaitingApproval:
        return 'Aguardando Aprovação';
      case OrderStatus.awaitingPayment:
        return 'Aguardando Pagamento';
      case OrderStatus.awaitingPart:
        return 'Aguardando Peça';
      case OrderStatus.inProgress:
        return 'Em Andamento';
      case OrderStatus.completed:
        return 'Concluída';
      case OrderStatus.cancelled:
        return 'Cancelada';
    }
  }

  IconData _getOrderIcon(OrderType type) {
    switch (type) {
      case OrderType.service:
        return Icons.build;
      case OrderType.budget:
        return Icons.calculate;
      case OrderType.sale:
        return Icons.shopping_cart;
    }
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Perfil da Empresa'),
            subtitle: const Text('Dados da oficina e logotipo para PDF'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompanyProfileScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações (em breve)'),
            subtitle: const Text('Preferências do aplicativo'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

IconData _statusIconFor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.hourglass_empty;
    case OrderStatus.awaitingApproval:
      return Icons.rate_review;
    case OrderStatus.awaitingPayment:
      return Icons.payments;
    case OrderStatus.awaitingPart:
      return Icons.inventory_2;
    case OrderStatus.inProgress:
      return Icons.build;
    case OrderStatus.completed:
      return Icons.check_circle;
    case OrderStatus.cancelled:
      return Icons.cancel;
  }
}
