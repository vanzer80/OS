import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/finance_service.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
  final String categoryType;
  final ValueChanged<String?> onCategoryChanged;
  final bool isRequired;
  final String? errorText;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    required this.categoryType,
    required this.onCategoryChanged,
    this.isRequired = false,
    this.errorText,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  final _newCategoryController = TextEditingController();
  bool _showNewCategoryField = false;
  bool _isCreatingCategory = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _createNewCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreatingCategory = true);
    try {
      final category = await ref
          .read(financeServiceProvider)
          .upsertCategory(name: name, type: widget.categoryType);
      widget.onCategoryChanged(category.id);
      _newCategoryController.clear();
      setState(() => _showNewCategoryField = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoria "$name" criada com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar categoria: $e')));
      }
    } finally {
      setState(() => _isCreatingCategory = false);
    }
  }

  Future<void> _deleteCategory(FinanceCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text(
          'Deseja excluir a categoria "${category.name}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(financeServiceProvider).deleteCategory(category.id);
        if (widget.selectedCategoryId == category.id) {
          widget.onCategoryChanged(null);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoria "${category.name}" excluída')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir categoria: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinanceCategory>>(
      future: ref
          .read(financeServiceProvider)
          .getCategories(type: widget.categoryType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];
        final hasError = widget.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown principal
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Categoria',
                errorText: hasError ? widget.errorText : null,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedCategoryId,
                  isExpanded: true,
                  hint: const Text('Selecione uma categoria'),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Expanded(child: Text(category.name)),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 16),
                              onSelected: (action) {
                                if (action == 'delete') {
                                  _deleteCategory(category);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16),
                                      SizedBox(width: 8),
                                      Text('Excluir'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: widget.onCategoryChanged,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Botão para criar nova categoria
            if (!_showNewCategoryField)
              TextButton.icon(
                onPressed: () => setState(() => _showNewCategoryField = true),
                icon: const Icon(Icons.add),
                label: const Text('Criar nova categoria'),
              ),

            // Campo para nova categoria
            if (_showNewCategoryField) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da nova categoria',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _createNewCategory(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isCreatingCategory ? null : _createNewCategory,
                    icon: _isCreatingCategory
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                  IconButton(
                    onPressed: () {
                      _newCategoryController.clear();
                      setState(() => _showNewCategoryField = false);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
