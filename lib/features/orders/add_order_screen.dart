import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../core/orders_service.dart';
import '../../core/clients_service.dart';
import '../../core/image_upload_service.dart';
import '../../core/company_profile_service.dart';
import '../clients/add_client_screen.dart';

class AddOrderScreen extends ConsumerStatefulWidget {
  const AddOrderScreen({super.key});

  @override
  ConsumerState<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends ConsumerState<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  OrderType _selectedType = OrderType.service;
  Client? _selectedClient;
  final _equipmentController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController(); // Novo campo: Marca
  final _serialNumberController =
      TextEditingController(); // Novo campo: Número de Série
  final _descriptionController = TextEditingController();

  final List<OrderItem> _items = [];
  final List<File> _images = [];
  final List<Uint8List> _webImages = [];
  final List<String> _imageTitles = [];
  final List<String> _imageDescs = [];
  bool _isLoading = false;
  String? _defaultPaymentTerms;
  String? _defaultWarranty;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final svc = ref.read(companyProfileServiceProvider);
      final profile = await svc.getProfile();
      setState(() {
        _defaultPaymentTerms = profile?.defaultPaymentTerms;
        _defaultWarranty = profile?.defaultWarranty;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _equipmentController.dispose();
    _modelController.dispose();
    _brandController.dispose(); // Novo campo
    _serialNumberController.dispose(); // Novo campo
    _descriptionController.dispose();
    super.dispose();
  }

  void _showClientSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Selecionar Cliente',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final clientsAsync = ref.watch(clientsProvider);
                    return clientsAsync.when(
                      data: (clients) {
                        if (clients.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 64),
                                const SizedBox(height: 16),
                                const Text('Nenhum cliente encontrado'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    final result = await Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AddClientScreen(),
                                          ),
                                        );
                                    if (result != null && mounted) {
                                      setState(() => _selectedClient = result);
                                    }
                                  },
                                  child: const Text('Cadastrar Cliente'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: Text(
                                  client.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(client.name),
                              subtitle: Text(
                                client.phone ?? client.email ?? '',
                              ),
                              onTap: () {
                                setState(() => _selectedClient = client);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Erro: $error')),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemDialog() {
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: '0.00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição do Item',
                hintText: 'Ex: Troca de óleo, Peça X, Serviço Y',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Preço Unitário',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final unitPrice =
                  double.tryParse(priceController.text.replaceAll(',', '.')) ??
                  0.0;
              final totalPrice = quantity * unitPrice;

              if (description.isNotEmpty) {
                setState(() {
                  _items.add(
                    OrderItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      orderId: '', // Será definido quando salvar
                      description: description,
                      quantity: quantity,
                      unit: 'un',
                      unitPrice: unitPrice,
                      totalPrice: totalPrice,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  int get _imagesCount => kIsWeb ? _webImages.length : _images.length;

  Future<void> _pickImages() async {
    if (_imagesCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo de 5 imagens permitido')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFiles.length + _imagesCount > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione no máximo 5 imagens')),
        );
      }
      return;
    }

    if (kIsWeb) {
      final bytesList = await Future.wait(
        pickedFiles.map((xf) => xf.readAsBytes()),
      );
      setState(() {
        _webImages.addAll(bytesList);
        _imageTitles.addAll(List.filled(bytesList.length, ''));
        _imageDescs.addAll(List.filled(bytesList.length, ''));
      });
    } else {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
        _imageTitles.addAll(List.filled(pickedFiles.length, ''));
        _imageDescs.addAll(List.filled(pickedFiles.length, ''));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_imagesCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo de 5 imagens permitido')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _webImages.add(bytes);
        });
      } else {
        setState(() {
          _images.add(File(photo.path));
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImages.removeAt(index);
        _imageTitles.removeAt(index);
        _imageDescs.removeAt(index);
      } else {
        _images.removeAt(index);
        _imageTitles.removeAt(index);
        _imageDescs.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item removido com sucesso!')));
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente para a ordem')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item à ordem')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obter o usuário atual
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro: Usuário não autenticado. Faça login novamente.',
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final order = ServiceOrder(
        id: '',
        userId: currentUser.id,
        clientId: _selectedClient?.id,
        orderNumber: '', // Será gerado automaticamente
        type: _selectedType,
        status: OrderStatus.pending,
        equipment: _equipmentController.text.trim().isEmpty
            ? null
            : _equipmentController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(), // Novo campo
        serialNumber: _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(), // Novo campo
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        paymentTerms: _defaultPaymentTerms,
        warranty: _defaultWarranty,
        totalAmount: _totalAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newOrder = await ref
          .read(ordersProvider.notifier)
          .createOrder(order);

      // Salvar itens da ordem
      for (var item in _items) {
        final orderItem = item.copyWith(orderId: newOrder.id);
        await ref.read(ordersServiceProvider).createOrderItem(orderItem);
      }

      // Fazer upload das imagens
      if (_imagesCount > 0) {
        try {
          final imageUploadService = ref.read(imageUploadServiceProvider);
          final uploadedUrls = kIsWeb
              ? await imageUploadService.uploadOrderImagesBytes(
                  _webImages,
                  newOrder.id,
                )
              : await imageUploadService.uploadOrderImages(
                  _images,
                  newOrder.id,
                );
          // Persistir URLs com título/descrição no banco de dados
          final records = <OrderImageRecord>[];
          for (var i = 0; i < uploadedUrls.length; i++) {
            records.add(
              OrderImageRecord(
                url: uploadedUrls[i],
                position: i,
                title: i < _imageTitles.length
                    ? (_imageTitles[i].trim().isEmpty
                          ? null
                          : _imageTitles[i].trim())
                    : null,
                description: i < _imageDescs.length
                    ? (_imageDescs[i].trim().isEmpty
                          ? null
                          : _imageDescs[i].trim())
                    : null,
              ),
            );
          }
          await ref
              .read(ordersServiceProvider)
              .addOrderImagesWithMeta(newOrder.id, records);
        } catch (imageError) {
          // Log do erro mas não falha a criação da ordem
          print('Erro ao fazer upload das imagens: $imageError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ordem ${_selectedType.name == 'service'
                  ? 'de Serviço'
                  : _selectedType.name == 'budget'
                  ? 'de Orçamento'
                  : 'de Venda'} criada com sucesso!',
            ),
          ),
        );
        Navigator.of(context).pop(newOrder);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar ordem: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Ordem'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              // Teste de conexão com Supabase
              try {
                final response = await Supabase.instance.client
                    .from('service_orders')
                    .select('count')
                    .count();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Conexão OK! Tabela existe')),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('❌ Erro: $error')));
                }
              }
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Testar Conexão',
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveOrder,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo de Ordem
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Ordem',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTypeButton(
                          title: 'Serviço',
                          subtitle: 'Conserto/Manut.',
                          type: OrderType.service,
                          icon: Icons.build,
                        ),
                        const SizedBox(width: 8),
                        _buildTypeButton(
                          title: 'Orçamento',
                          subtitle: 'Cotação/Avaliação',
                          type: OrderType.budget,
                          icon: Icons.calculate,
                        ),
                        const SizedBox(width: 8),
                        _buildTypeButton(
                          title: 'Venda',
                          subtitle: 'Equip./Peças',
                          type: OrderType.sale,
                          icon: Icons.shopping_cart,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cliente
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Cliente'),
                subtitle: _selectedClient != null
                    ? Text(_selectedClient!.name)
                    : const Text('Selecionar cliente...'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showClientSelection,
              ),
            ),

            // Botão de cliente teste
            if (_selectedClient == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Criar cliente de teste
                    final testClient = Client(
                      id: 'test-client-123',
                      name: 'Cliente Teste',
                      email: 'teste@email.com',
                      phone: '(11) 99999-9999',
                      address: 'Rua Teste, 123',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    setState(() {
                      _selectedClient = testClient;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente de teste selecionado!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.science),
                  label: const Text('Usar Cliente Teste'),
                ),
              ),

            const SizedBox(height: 16),

            // Equipamento e Modelo
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _equipmentController,
                    decoration: const InputDecoration(
                      labelText: 'Equipamento',
                      hintText: 'Ex: Motor, Bomba, Compressor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'Ex: XYZ-1000, AB-500',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Marca e Número de Série
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      hintText: 'Ex: Bosch, Makita, Stanley',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Série',
                      hintText: 'Ex: SN123456789',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição do Serviço',
                hintText: 'Descreva o que precisa ser feito...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Itens
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Itens da Ordem',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                // Adicionar item de teste
                                final testItem = OrderItem(
                                  id: '',
                                  orderId: '',
                                  description: 'Teste - Troca de óleo',
                                  quantity: 1,
                                  unit: 'un',
                                  unitPrice: 50.0,
                                  totalPrice: 50.0,
                                  createdAt: DateTime.now(),
                                );
                                setState(() {
                                  _items.add(testItem);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Item de teste adicionado!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.science),
                              tooltip: 'Adicionar Item Teste',
                            ),
                            IconButton(
                              onPressed: _showAddItemDialog,
                              icon: const Icon(Icons.add),
                              tooltip: 'Adicionar Item',
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_items.isEmpty)
                      const Center(child: Text('Nenhum item adicionado'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            title: Text(item.description),
                            subtitle: Text(
                              '${item.quantity}x R\$ ${item.unitPrice.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                                ),
                                IconButton(
                                  onPressed: () => _removeItem(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'Remover Item',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${_totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Imagens
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Imagens ($_imagesCount/5)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              tooltip: 'Tirar Foto',
                            ),
                            IconButton(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.photo_library),
                              tooltip: 'Galeria',
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_imagesCount > 0)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imagesCount,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb
                                            ? Image.memory(
                                                _webImages[index],
                                                width: 120,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                _images[index],
                                                width: 120,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'Título',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                      onChanged: (v) {
                                        _imageTitles[index] = v;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'Descrição',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                      onChanged: (v) {
                                        _imageDescs[index] = v;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required String subtitle,
    required OrderType type,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
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
