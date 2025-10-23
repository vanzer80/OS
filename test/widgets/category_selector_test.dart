import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:os_express_flutter/features/finance/widgets/category_selector.dart';
import 'package:os_express_flutter/core/finance_service.dart';

void main() {
  group('CategorySelector Widget Tests', () {
    testWidgets('should display dropdown with categories', (
      WidgetTester tester,
    ) async {
      // Mock categories
      final mockCategories = [
        FinanceCategory(
          id: '1',
          name: 'Alimentação',
          type: 'expense',
          userId: 'user1',
          createdAt: DateTime.now(),
        ),
        FinanceCategory(
          id: '2',
          name: 'Transporte',
          type: 'expense',
          userId: 'user1',
          createdAt: DateTime.now(),
        ),
      ];

      // Create a mock provider container
      final container = ProviderContainer(
        overrides: [
          financeServiceProvider.overrideWith(
            (ref) => MockFinanceService(mockCategories),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategorySelector(
                selectedCategoryId: null,
                categoryType: 'expense',
                onCategoryChanged: (id) {},
                isRequired: true,
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the dropdown is displayed
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Verify that categories are loaded
      expect(find.text('Selecione uma categoria'), findsOneWidget);
    });

    testWidgets('should show error when required and no category selected', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          financeServiceProvider.overrideWith((ref) => MockFinanceService([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategorySelector(
                selectedCategoryId: null,
                categoryType: 'expense',
                onCategoryChanged: (id) {},
                isRequired: true,
                errorText: 'Categoria é obrigatória',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error text is displayed
      expect(find.text('Categoria é obrigatória'), findsOneWidget);
    });

    testWidgets('should allow creating new category', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          financeServiceProvider.overrideWith((ref) => MockFinanceService([])),
        ],
      );

      String? createdCategoryId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CategorySelector(
                selectedCategoryId: null,
                categoryType: 'expense',
                onCategoryChanged: (id) {
                  createdCategoryId = id;
                },
                isRequired: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the new category text field
      final newCategoryField = find.byType(TextFormField).last;
      await tester.tap(newCategoryField);
      await tester.enterText(newCategoryField, 'Nova Categoria');
      await tester.pumpAndSettle();

      // Find and tap the create button
      final createButton = find.byIcon(Icons.add);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify that the callback was called
      expect(createdCategoryId, isNotNull);
    });
  });
}

// Mock FinanceService for testing
class MockFinanceService extends FinanceService {
  final List<FinanceCategory> _categories;

  MockFinanceService(this._categories);

  @override
  Future<List<FinanceCategory>> getCategories({required String type}) async {
    return _categories.where((cat) => cat.type == type).toList();
  }

  @override
  Future<FinanceCategory> upsertCategory({
    required String name,
    required String type,
    String? categoryId,
  }) async {
    final newCategory = FinanceCategory(
      id: categoryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      userId: 'user1',
      createdAt: DateTime.now(),
    );
    _categories.add(newCategory);
    return newCategory;
  }

  @override
  Future<void> deleteCategory({required String categoryId}) async {
    _categories.removeWhere((cat) => cat.id == categoryId);
  }

  @override
  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    final index = _categories.indexWhere((cat) => cat.id == categoryId);
    if (index != -1) {
      _categories[index] = FinanceCategory(
        id: categoryId,
        name: name,
        type: _categories[index].type,
        userId: _categories[index].userId,
        createdAt: _categories[index].createdAt,
      );
    }
  }
}
