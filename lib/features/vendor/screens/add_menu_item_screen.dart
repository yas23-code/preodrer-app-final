import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/add_menu_item_provider.dart';

class AddMenuItemScreen extends ConsumerStatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  ConsumerState<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends ConsumerState<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _packingChargeController = TextEditingController(text: '0');
  final _prepTimeController = TextEditingController();

  bool _isAvailable = true;
  File? _itemImage;
  File? _categoryImage;

  final _imagePicker = ImagePicker();

  static const _defaultCategories = [
    'Snacks',
    'Beverages',
    'Meals',
    'Desserts',
    'Combos',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _packingChargeController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCategory) async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isCategory) {
          _categoryImage = File(picked.path);
        } else {
          _itemImage = File(picked.path);
        }
      });
    }
  }

  void _showDefaultCategories() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Standard Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _defaultCategories.length,
              itemBuilder: (context, index) {
                final cat = _defaultCategories[index];
                return ListTile(
                  title: Text(cat),
                  onTap: () {
                    _categoryController.text = cat;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final packingCharge =
        double.tryParse(_packingChargeController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();
    final prepTime = _prepTimeController.text.trim();
    final categoryName = _categoryController.text.trim();

    await ref.read(addMenuItemProvider.notifier).addMenuItem(
          name: name,
          price: price,
          packingCharge: packingCharge,
          description: description,
          prepTime: prepTime.isEmpty ? null : prepTime,
          categoryName: categoryName,
          isAvailable: _isAvailable,
          itemImage: _itemImage,
          categoryImage: _categoryImage,
        );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _packingChargeController.text = '0';
    _prepTimeController.clear();
    setState(() {
      _isAvailable = true;
      _itemImage = null;
      _categoryImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(addMenuItemProvider);

    ref.listen(addMenuItemProvider, (previous, next) {
      if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item added successfully!')),
        );
        _resetForm();
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: ${next.error}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Menu Item'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Basic Info',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'))
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price is required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _packingChargeController,
                            decoration: const InputDecoration(
                              labelText: 'Packing Charge (₹)',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'))
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prepTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (mins)',
                        hintText: 'Auto',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text('Category',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _showDefaultCategories,
                          icon: const Icon(Icons.list),
                          label: const Text('Add Default'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_categoryImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_categoryImage!,
                                width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton.icon(
                          onPressed: () => _pickImage(true),
                          icon: const Icon(Icons.image),
                          label: Text(_categoryImage == null
                              ? 'Add Category Image'
                              : 'Change Category Image'),
                        ),
                        if (_categoryImage != null)
                          IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: () =>
                                setState(() => _categoryImage = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text('Item Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_itemImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_itemImage!,
                                width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(false),
                                icon: const Icon(Icons.upload_file),
                                label: Text(_itemImage == null
                                    ? 'Upload Item Image'
                                    : 'Change Image'),
                              ),
                              if (_itemImage != null)
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _itemImage = null),
                                  icon: Icon(Icons.delete,
                                      color: colorScheme.error),
                                  label: Text('Remove',
                                      style:
                                          TextStyle(color: colorScheme.error)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Available for Orders'),
                      subtitle: const Text(
                          'Turn off to hide this item from the menu'),
                      value: _isAvailable,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : _submit,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
