import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
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
  final List<Uint8List> _webImages = [];
  final List<OrderImageRecord> _persistedRecords = [];
  final List<String> _persistedTitles = [];
  final List<String> _persistedDescs = [];
  final List<String> _newTitles = [];
  final List<String> _newDescs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _loadOrderImages() async {
    try {
      final records = await ref.read(ordersServiceProvider).getOrderImages(widget.order.id);
      if (!mounted) return;
      setState(() {
        _persistedRecords
          ..clear()
          ..addAll(records);
        _persistedTitles
          ..clear()
          ..addAll(records.map((e) => e.title ?? ''));
        _persistedDescs
          ..clear()
          ..addAll(records.map((e) => e.description ?? ''));
      });
    } catch (_) {}
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
    _loadOrderImages();
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
                      unit: 'un',
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
                    unit: item.unit,
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

  int get _localImagesCount => kIsWeb ? _webImages.length : _images.length;
  int get _totalImagesCount => _persistedRecords.length + _localImagesCount;

  Future<void> _pickImages() async {
    if (_totalImagesCount >= 5) {
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

    if (pickedFiles.length + _totalImagesCount > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione no máximo 5 imagens')),
        );
      }
      return;
    }

    if (kIsWeb) {
      final futures = pickedFiles.map((xf) => xf.readAsBytes());
      final bytesList = await Future.wait(futures);
      setState(() {
        _webImages.addAll(bytesList);
        _newTitles.addAll(List.filled(bytesList.length, ''));
        _newDescs.addAll(List.filled(bytesList.length, ''));
      });
    } else {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
        _newTitles.addAll(List.filled(pickedFiles.length, ''));
        _newDescs.addAll(List.filled(pickedFiles.length, ''));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_totalImagesCount >= 5) {
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
          _newTitles.add('');
          _newDescs.add('');
        });
      } else {
        setState(() {
          _images.add(File(photo.path));
          _newTitles.add('');
          _newDescs.add('');
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImages.removeAt(index);
        if (index < _newTitles.length) _newTitles.removeAt(index);
        if (index < _newDescs.length) _newDescs.removeAt(index);
      } else {
        _images.removeAt(index);
        if (index < _newTitles.length) _newTitles.removeAt(index);
        if (index < _newDescs.length) _newDescs.removeAt(index);
      }
    });
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

      // Imagens: atualizar metadados mesmo sem novas imagens; se houver novas, combinar
      if (_localImagesCount > 0) {
        try {
          final imageUploadService = ref.read(imageUploadServiceProvider);
          final ordersSvc = ref.read(ordersServiceProvider);
          // Buscar já persistidas com meta
          final existingRecords = await ordersSvc.getOrderImages(widget.order.id);
          // Enviar imagens e obter URLs públicas
          final uploadedUrls = kIsWeb
              ? await imageUploadService.uploadOrderImagesBytes(_webImages, widget.order.id)
              : await imageUploadService.uploadOrderImages(_images, widget.order.id);
          // Atualizar metadados editados das persistidas
          final updatedExisting = <OrderImageRecord>[];
          for (var i = 0; i < existingRecords.length; i++) {
            final rec = existingRecords[i];
            final title = i < _persistedTitles.length ? (_persistedTitles[i].trim().isEmpty ? null : _persistedTitles[i].trim()) : rec.title;
            final desc = i < _persistedDescs.length ? (_persistedDescs[i].trim().isEmpty ? null : _persistedDescs[i].trim()) : rec.description;
            updatedExisting.add(OrderImageRecord(url: rec.url, position: i, title: title, description: desc));
          }

          // Converter novas imagens para records (com meta capturada nesta tela)
          final newRecords = <OrderImageRecord>[];
          for (var i = 0; i < uploadedUrls.length; i++) {
            final t = i < _newTitles.length ? (_newTitles[i].trim().isEmpty ? null : _newTitles[i].trim()) : null;
            final d = i < _newDescs.length ? (_newDescs[i].trim().isEmpty ? null : _newDescs[i].trim()) : null;
            newRecords.add(OrderImageRecord(url: uploadedUrls[i], position: updatedExisting.length + i, title: t, description: d));
          }

          final allRecords = [...updatedExisting, ...newRecords];
          await ordersSvc.deleteImagesForOrder(widget.order.id);
          await ordersSvc.addOrderImagesWithMeta(widget.order.id, allRecords);
          // Limpar buffers locais e recarregar persistidas
          setState(() {
            _webImages.clear();
            _images.clear();
            _newTitles.clear();
            _newDescs.clear();
          });
          await _loadOrderImages();
        } catch (imageError) {
          // ignore: avoid_print
          print('Erro ao atualizar imagens: $imageError');
        }
      } else {
        // Sem novas imagens: apenas atualizar metadados das existentes
        try {
          final ordersSvc = ref.read(ordersServiceProvider);
          final existingRecords = await ordersSvc.getOrderImages(widget.order.id);
          final updatedExisting = <OrderImageRecord>[];
          for (var i = 0; i < existingRecords.length; i++) {
            final rec = existingRecords[i];
            final title = i < _persistedTitles.length ? (_persistedTitles[i].trim().isEmpty ? null : _persistedTitles[i].trim()) : rec.title;
            final desc = i < _persistedDescs.length ? (_persistedDescs[i].trim().isEmpty ? null : _persistedDescs[i].trim()) : rec.description;
            updatedExisting.add(OrderImageRecord(url: rec.url, position: i, title: title, description: desc));
          }
          await ordersSvc.deleteImagesForOrder(widget.order.id);
          await ordersSvc.addOrderImagesWithMeta(widget.order.id, updatedExisting);
          await _loadOrderImages();
        } catch (imageError) {
          // ignore: avoid_print
          print('Erro ao atualizar metadados das imagens: $imageError');
        }
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
    final media = MediaQuery.of(context);
    final bottomSafeArea = media.padding.bottom + media.viewPadding.bottom;
    final keyboardInset = media.viewInsets.bottom; // > 0 quando teclado aberto
    final bottomPadding = 16.0 + bottomSafeArea + (keyboardInset > 0 ? keyboardInset : 0);

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
      body: SafeArea(
        bottom: true,
        child: Form(
          key: _formKey,
          child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
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
                        Text('Imagens (${_totalImagesCount}/5)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), tooltip: 'Tirar Foto'),
                            IconButton(onPressed: _pickImages, icon: const Icon(Icons.photo_library), tooltip: 'Galeria'),
                          ],
                        ),
                      ],
                    ),
                    if (_persistedRecords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _persistedRecords.length,
                          itemBuilder: (context, index) {
                            final rec = _persistedRecords[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(rec.url, width: 120, height: 90, fit: BoxFit.cover),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      decoration: const InputDecoration(isDense: true, labelText: 'Título'),
                                      controller: TextEditingController(text: _persistedTitles[index]),
                                      onChanged: (v) => _persistedTitles[index] = v,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      decoration: const InputDecoration(isDense: true, labelText: 'Descrição'),
                                      controller: TextEditingController(text: _persistedDescs[index]),
                                      onChanged: (v) => _persistedDescs[index] = v,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_localImagesCount > 0)
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _localImagesCount,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb
                                            ? Image.memory(_webImages[index], width: 120, height: 90, fit: BoxFit.cover)
                                            : Image.file(_images[index], width: 120, height: 90, fit: BoxFit.cover),
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
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      decoration: const InputDecoration(isDense: true, labelText: 'Título'),
                                      onChanged: (v) => _newTitles[index] = v,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      decoration: const InputDecoration(isDense: true, labelText: 'Descrição'),
                                      onChanged: (v) => _newDescs[index] = v,
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
