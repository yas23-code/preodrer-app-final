import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../menu/models/menu_item.dart';
import '../providers/vendor_menu_provider.dart';
import 'add_menu_item_screen.dart';
import 'edit_menu_item_modal.dart';
import '../../../core/supabase_client.dart';
import '../../../core/constants.dart';

class ManageMenuScreen extends ConsumerStatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  ConsumerState<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends ConsumerState<ManageMenuScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteCategoryConfirmation(BuildContext context, String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$categoryName"?\n\nItems in this category will not be deleted, but will become uncategorized.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ref.read(vendorMenuActionProvider).deleteCategory(categoryId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$categoryName" deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete category: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemConfirmation(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ref.read(vendorMenuActionProvider).deleteMenuItem(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item "${item.name}" deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete item: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openEditModal(MenuItem item, String categoryName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditMenuItemModal(
        item: item,
        initialCategoryName: categoryName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final menuItemsAsync = ref.watch(vendorMenuItemsProvider);
    final categoriesAsync = ref.watch(vendorCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Menu Item',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMenuItemScreen()),
              );
            },
          ),
        ],
      ),
      body: menuItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading menu items: $e')),
        data: (allItems) {
          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading categories: $e')),
            data: (categories) {
              
              // Client-side filtering (Search + Category)
              final filteredItems = allItems.where((item) {
                final matchesCategory = _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
                final matchesSearch = _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              // Helper to find category name
              String getCategoryName(String? catId) {
                if (catId == null) return 'Uncategorized';
                final cat = categories.where((c) => c['id'] == catId).firstOrNull;
                return cat != null ? cat['name'] : 'Uncategorized';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Categories Panel
                  Container(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Your current categories',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              // "All Items" Chip
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text('All Items (${allItems.length})'),
                                  selected: _selectedCategoryId == null,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedCategoryId = null);
                                  },
                                ),
                              ),
                              
                              // Category Chips
                              ...categories.map((cat) {
                                final count = allItems.where((item) => item.categoryId == cat['id']).length;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: InputChip(
                                    label: Text('${cat['name']} ($count)'),
                                    selected: _selectedCategoryId == cat['id'],
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategoryId = selected ? cat['id'] : null;
                                      });
                                    },
                                    onDeleted: () => _showDeleteCategoryConfirmation(context, cat['id'], cat['name']),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search menu items...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),

                  // Menu Items List
                  Expanded(
                    child: filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'No items found.',
                            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final catName = getCategoryName(item.categoryId);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item Image
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: (() {
                                        String? resolvedUrl = item.imageUrl;
                                        if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
                                          if (!resolvedUrl.startsWith('http')) {
                                            final supabase = ref.read(supabaseClientProvider);
                                            resolvedUrl = supabase.storage
                                                .from(kFoodImagesBucketName)
                                                .getPublicUrl(resolvedUrl);
                                          }
                                        }
                                        return resolvedUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(resolvedUrl, fit: BoxFit.cover),
                                              )
                                            : Icon(Icons.fastfood, color: colorScheme.onSurfaceVariant);
                                      })(),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.name,
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Text(
                                                '₹${item.price.toStringAsFixed(2)}',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            catName,
                                            style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                item.isAvailable ? 'Available' : 'Unavailable',
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: item.isAvailable ? colorScheme.primary : colorScheme.error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Switch(
                                                value: item.isAvailable,
                                                onChanged: (val) async {
                                                  try {
                                                    await ref.read(vendorMenuActionProvider).toggleItemAvailability(item, val);
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Failed to update availability: $e')),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Actions
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          color: colorScheme.primary,
                                          onPressed: () => _openEditModal(item, catName),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          color: colorScheme.error,
                                          onPressed: () => _showDeleteItemConfirmation(context, item),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
