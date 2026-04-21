import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../menu/models/menu_item.dart';
import '../providers/vendor_menu_provider.dart';

class EditMenuItemModal extends ConsumerStatefulWidget {
  final MenuItem item;
  final String initialCategoryName;

  const EditMenuItemModal({
    super.key,
    required this.item,
    required this.initialCategoryName,
  });

  @override
  ConsumerState<EditMenuItemModal> createState() => _EditMenuItemModalState();
}

class _EditMenuItemModalState extends ConsumerState<EditMenuItemModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _packingChargeController;
  late final TextEditingController _prepTimeController;

  late bool _isAvailable;
  File? _itemImage;
  File? _categoryImage;
  bool _isLoading = false;
  bool _isImageRemoved = false;

  final _imagePicker = ImagePicker();

  static const _defaultCategories = [
    'Snacks',
    'Beverages',
    'Meals',
    'Desserts',
    'Combos',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _categoryController = TextEditingController(text: widget.initialCategoryName);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _priceController = TextEditingController(text: widget.item.price.toString());
    _packingChargeController = TextEditingController(text: widget.item.packingCharge.toString());
    _prepTimeController = TextEditingController(text: widget.item.prepTime?.toString() ?? '');
    _isAvailable = widget.item.isAvailable;
  }

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

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final packingCharge =
          double.tryParse(_packingChargeController.text.trim()) ?? 0.0;
      final description = _descriptionController.text.trim();
      final prepTime = _prepTimeController.text.trim();
      final categoryName = _categoryController.text.trim();

      await ref.read(vendorMenuActionProvider).updateMenuItem(
            currentItem: widget.item,
            name: name,
            price: price,
            packingCharge: packingCharge,
            description: description,
            prepTime: prepTime.isEmpty ? null : prepTime,
            categoryName: categoryName,
            isAvailable: _isAvailable,
            newItemImage: _itemImage,
            newCategoryImage: _categoryImage,
            isImageRemoved: _isImageRemoved,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item updated successfully!')),
        );
        Navigator.pop(context); // Close the modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // View insets padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 24.0,
        bottom: bottomPadding + 24.0,
      ),
      // Max height is 90% of screen to allow scrolling
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Menu Item', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
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
                              ] else if (widget.item.imageUrl != null && !_isImageRemoved) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(widget.item.imageUrl!,
                                      width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() => _isImageRemoved = false);
                                        _pickImage(false);
                                      },
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(_itemImage == null && (widget.item.imageUrl == null || _isImageRemoved)
                                          ? 'Upload Item Image'
                                          : 'Change Image'),
                                    ),
                                    if (_itemImage != null)
                                      TextButton.icon(
                                        onPressed: () =>
                                            setState(() => _itemImage = null),
                                        icon: Icon(Icons.undo,
                                            color: colorScheme.onSurfaceVariant),
                                        label: Text('Revert to original',
                                            style:
                                                TextStyle(color: colorScheme.onSurfaceVariant)),
                                      ),
                                    if (_itemImage == null && widget.item.imageUrl != null && !_isImageRemoved)
                                      TextButton.icon(
                                        onPressed: () =>
                                            setState(() => _isImageRemoved = true),
                                        icon: Icon(Icons.delete,
                                            color: colorScheme.error),
                                        label: Text('Remove Image',
                                            style:
                                                TextStyle(color: colorScheme.error)),
                                      ),
                                    if (_isImageRemoved)
                                      TextButton.icon(
                                        onPressed: () =>
                                            setState(() => _isImageRemoved = false),
                                        icon: Icon(Icons.undo,
                                            color: colorScheme.onSurfaceVariant),
                                        label: Text('Undo Remove',
                                            style:
                                                TextStyle(color: colorScheme.onSurfaceVariant)),
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
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isLoading ? null : _submit,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Save Changes'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
