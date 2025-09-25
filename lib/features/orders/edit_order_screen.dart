import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../core/orders_service.dart';
import '../../core/clients_service.dart';
import '../../core/image_upload_service.dart';
import '../clients/add_client_screen.dart';

class EditOrderScreen extends ConsumerStatefulWidget {
  final ServiceOrder order;

  const EditOrderScreen({super.key, required this.order});

  @override
  ConsumerState<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends ConsumerState<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late OrderType _selectedType;
  Client? _selectedClient;
  final _equipmentController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<OrderItem> _items = [];
  final List<File> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _selectedType = widget.order.type;
    _equipmentController.text = widget.order.equipment ?? '';
    _modelController.text = widget.order.model ?? '';
    _brandController.text = widget.order.brand ?? '';
    _serialNumberController.text = widget.order.serialNumber ?? '';
    _descriptionController.text = widget.order.description ?? '';
    _loadClient();
    _loadOrderItems();
  }

  Future<void> _loadClient() async {
    if (widget.order.clientId != null) {
      try {
        final client = await ref.read(clientsServiceProvider).getClientById(widget.order.clientId!);
        if (mounted) {
          setState(() => _selectedClient = client);
        }
      } catch (_) {}
    }
  }

  Future<void> _loadOrderItems() async {
    try {
      final items = await ref.read(ordersServiceProvider).getOrderItems(widget.order.id);
      if (mounted) {
        setState(() => _items.addAll(items));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _equipmentController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _serialNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showClientSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('Selecionar Cliente'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddClientScreen(),
                    ),
                  );
                  if (result != null && mounted) {
                    setState(() => _selectedClient = result);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Cadastrar Cliente'),
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final clientsAsync = ref.watch(clientsProvider);
                  return clientsAsync.when(
                    data: (clients) => ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ListTile(
                          title: Text(client.name),
                          subtitle: Text(client.phone ?? client.email ?? ''),
                          onTap: () {
                            setState(() => _selectedClient = client);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Erro: $error')),
                  );
                },
              ),
            ),
          ],
        ),
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
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Preço Unitário', prefixText: 'R\$ '),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final unitPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
              if (description.isNotEmpty) {
                setState(() {
                  _items.add(
                    OrderItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      orderId: '',
                      description: description,
                      quantity: quantity,
                      unitPrice: unitPrice,
                      totalPrice: quantity * unitPrice,
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

  void _showEditItemDialog(int index) {
    final item = _items[index];
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição do Item'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Preço Unitário', prefixText: 'R\$ '),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _items.removeAt(index));
              Navigator.of(context).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final unitPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
              if (description.isNotEmpty) {
                setState(() {
                  _items[index] = item.copyWith(
                    description: description,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    totalPrice: quantity * unitPrice,
                  );
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
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

    if (pickedFiles.length + _images.length > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione no máximo 5 imagens')),
        );
      }
      return;
    }

    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)));
    });
  }

  Future<void> _takePhoto() async {
    if (_images.length >= 5) {
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
      setState(() {
        _images.add(File(photo.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removido com sucesso!')),
    );
  }

  double get _totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _updateOrder() async {
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
      final updatedOrder = widget.order.copyWith(
        clientId: _selectedClient?.id,
        type: _selectedType,
        equipment: _equipmentController.text.trim().isEmpty ? null : _equipmentController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        totalAmount: _totalAmount,
        updatedAt: DateTime.now(),
      );

      await ref.read(ordersProvider.notifier).updateOrder(widget.order.id, updatedOrder);

      await ref.read(ordersServiceProvider).deleteOrderItems(widget.order.id);
      for (var item in _items) {
        final orderItem = item.copyWith(orderId: widget.order.id);
        await ref.read(ordersServiceProvider).createOrderItem(orderItem);
      }

      if (_images.isNotEmpty) {
        try {
          final imageUploadService = ref.read(imageUploadServiceProvider);
          await imageUploadService.uploadOrderImages(_images, widget.order.id);
        } catch (imageError) {
          // Não bloquear a atualização por erro de upload
          // ignore: avoid_print
          print('Erro ao fazer upload das imagens: $imageError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ordem ${_selectedType.name == 'service' ? 'de Serviço' : _selectedType.name == 'budget' ? 'de Orçamento' : 'de Venda'} atualizada com sucesso!'),
          ),
        );
        Navigator.of(context).pop(updatedOrder);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar ordem: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Ordem ${widget.order.orderNumber}'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateOrder,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Ordem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTypeButton(OrderType.service, 'Serviço', Icons.build, Colors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeButton(OrderType.budget, 'Orçamento', Icons.calculate, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeButton(OrderType.sale, 'Venda', Icons.shopping_cart, Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Cliente'),
                subtitle: _selectedClient != null ? Text(_selectedClient!.name) : const Text('Selecionar cliente...'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showClientSelection,
              ),
            ),
            const SizedBox(height: 16),
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
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição do Serviço',
                hintText: 'Descreva detalhadamente o serviço a ser realizado...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Itens da Ordem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: _showAddItemDialog, icon: const Icon(Icons.add), tooltip: 'Adicionar Item'),
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
                            subtitle: Text('${item.quantity}x R\$ ${item.unitPrice.toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('R\$ ${item.totalPrice.toStringAsFixed(2)}'),
                                IconButton(
                                  onPressed: () => _removeItem(index),
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  tooltip: 'Remover Item',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showEditItemDialog(index),
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
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'R\$ ${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Imagens (${_images.length}/5)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), tooltip: 'Tirar Foto'),
                            IconButton(onPressed: _pickImages, icon: const Icon(Icons.photo_library), tooltip: 'Galeria'),
                          ],
                        ),
                      ],
                    ),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _images[index],
                                      width: 100,
                                      height: 100,
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
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(OrderType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? color : Theme.of(context).colorScheme.outline, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withAlpha(25) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: isSelected ? color : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
