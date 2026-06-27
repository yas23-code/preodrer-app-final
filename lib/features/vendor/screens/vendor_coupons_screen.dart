import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../menu/models/menu_item.dart';
import '../../menu/providers/menu_provider.dart';
import '../providers/coupons_provider.dart';

class VendorCouponsScreen extends ConsumerStatefulWidget {
  const VendorCouponsScreen({super.key});

  @override
  ConsumerState<VendorCouponsScreen> createState() => _VendorCouponsScreenState();
}

class _VendorCouponsScreenState extends ConsumerState<VendorCouponsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _expiryController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _showAddCouponDialog() async {
    _codeController.clear();
    _discountController.clear();
    _expiryController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Coupon'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code (e.g. FLAT50)',
                      hintText: 'Enter uppercase code',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Amount (₹) *',
                      hintText: 'e.g. 50',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0) return 'Must be a valid positive number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'e.g. 31 Dec 2026',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final code = _codeController.text.trim().toUpperCase();
                  final discountVal = double.tryParse(_discountController.text.trim()) ?? 0.0;
                  final expiry = _expiryController.text.trim();

                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    final supabase = ref.read(supabaseClientProvider);
                    final catId = await ref.read(couponsCategoryIdProvider.future);
                    final canteenId = ref.read(selectedCanteenIdProvider);

                    if (catId == null) {
                      throw Exception("Failed to resolve virtual coupons category");
                    }

                    await supabase.from(kMenuItemsTableName).insert({
                      'name': code,
                      'price': discountVal,
                      'description': 'Flat ₹${discountVal.toStringAsFixed(0)} OFF on your order',
                      'category_id': catId,
                      'canteen_id': canteenId,
                      'is_available': true,
                      'image_url': expiry,
                    });

                    ref.invalidate(couponsProvider);
                    navigator.pop();

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Coupon "$code" created successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to create coupon: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final couponsAsync = ref.watch(couponsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        title: const Text('Manage Coupons', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCouponDialog,
        backgroundColor: const Color(0xFFFFC300),
        foregroundColor: const Color(0xFF2B1D0E),
        child: const Icon(Icons.add),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFC300))),
        error: (e, _) => Center(child: Text('Error loading coupons: $e')),
        data: (coupons) {
          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No coupons active', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: coupon.isAvailable ? Colors.white : Colors.white.withValues(alpha: 0.6),
                elevation: coupon.isAvailable ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: coupon.isAvailable ? colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: coupon.isAvailable ? colorScheme.primary.withValues(alpha: 0.12) : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_offer,
                          color: coupon.isAvailable ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: coupon.isAvailable ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flat ₹${coupon.price.toStringAsFixed(0)} OFF',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: coupon.isAvailable ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Expires on ${coupon.imageUrl ?? 'N/A'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: coupon.isAvailable,
                            onChanged: (val) async {
                              try {
                                final supabase = ref.read(supabaseClientProvider);
                                await supabase
                                    .from(kMenuItemsTableName)
                                    .update({'is_available': val})
                                    .eq('id', coupon.id);
                                ref.invalidate(couponsProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update status: $e')),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              try {
                                final supabase = ref.read(supabaseClientProvider);
                                await supabase
                                    .from(kMenuItemsTableName)
                                    .delete()
                                    .eq('id', coupon.id);
                                ref.invalidate(couponsProvider);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Coupon "${coupon.name}" deleted')),
                                );
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
