import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/supabase_client.dart';
import '../../../core/storage_service.dart';
import '../providers/vendor_menu_provider.dart';

class VendorSettingsTab extends ConsumerStatefulWidget {
  final Map<String, dynamic>? canteenData;
  final VoidCallback onSignOut;

  const VendorSettingsTab({
    super.key,
    required this.canteenData,
    required this.onSignOut,
  });

  @override
  ConsumerState<VendorSettingsTab> createState() => _VendorSettingsTabState();
}

class _VendorSettingsTabState extends ConsumerState<VendorSettingsTab> {
  final _imagePicker = ImagePicker();
  bool _isSaving = false;

  Future<void> _updateCanteenFields(Map<String, dynamic> fields) async {
    final canteenId = widget.canteenData?['id'];
    if (canteenId == null) return;

    setState(() => _isSaving = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('canteens')
          .update(fields)
          .eq('id', canteenId);

      // Invalidate the provider to sync UI instantly
      ref.invalidate(vendorCanteenProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('max_concurrent_orders') ||
            errorMsg.contains('PGRST204') ||
            errorMsg.contains('bank_name') ||
            errorMsg.contains('opening_time')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFFFFF8E7),
              title: const Text('Database Update Required', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
              content: const SingleChildScrollView(
                child: Text(
                  'The database schema is missing the required columns for timings/limits/bank payouts.\n\n'
                  'Please run the following SQL in your Supabase SQL Editor:\n\n'
                  'ALTER TABLE canteens \n'
                  'ADD COLUMN IF NOT EXISTS bank_name TEXT,\n'
                  'ADD COLUMN IF NOT EXISTS account_number TEXT,\n'
                  'ADD COLUMN IF NOT EXISTS ifsc_code TEXT,\n'
                  'ADD COLUMN IF NOT EXISTS auto_timing_off BOOLEAN DEFAULT false,\n'
                  'ADD COLUMN IF NOT EXISTS opening_time TEXT DEFAULT \'08:00\',\n'
                  'ADD COLUMN IF NOT EXISTS closing_time TEXT DEFAULT \'20:00\',\n'
                  'ADD COLUMN IF NOT EXISTS max_concurrent_orders INTEGER DEFAULT 10;'
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final file = File(picked.path);
      final publicUrl = await storage.uploadImage(file, folder: 'canteen-logos', bucket: 'canteen-images');

      await _updateCanteenFields({'image_url': publicUrl});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSaving = false);
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: widget.canteenData?['name'] ?? '');
    final locCtrl = TextEditingController(text: widget.canteenData?['location'] ?? '');
    final emailCtrl = TextEditingController(text: widget.canteenData?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: widget.canteenData?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8E7),
          title: const Text('Edit Store Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Canteen Name *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Phone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC300), foregroundColor: const Color(0xFF2B1D0E)),
              onPressed: () {
                Navigator.pop(context);
                _updateCanteenFields({
                  'name': nameCtrl.text.trim(),
                  'location': locCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showTimingSettingsDialog() {
    // Graceful check if fields are missing in table
    bool autoOff = false;
    String opening = '08:00';
    String closing = '20:00';

    try {
      autoOff = widget.canteenData?['auto_timing_off'] as bool? ?? false;
      opening = widget.canteenData?['opening_time'] as String? ?? '08:00';
      closing = widget.canteenData?['closing_time'] as String? ?? '20:00';
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFF8E7),
              title: const Text('Canteen Timings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Auto-close Canteen', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Turn off orders automatically outside working hours'),
                    value: autoOff,
                    activeColor: const Color(0xFFFFC300),
                    onChanged: (val) => setDialogState(() => autoOff = val),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Opening Time', style: TextStyle(fontSize: 14)),
                    trailing: Text(opening, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(opening.split(':')[0]),
                          minute: int.parse(opening.split(':')[1]),
                        ),
                      );
                      if (time != null) {
                        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setDialogState(() => opening = formatted);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Closing Time', style: TextStyle(fontSize: 14)),
                    trailing: Text(closing, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(closing.split(':')[0]),
                          minute: int.parse(closing.split(':')[1]),
                        ),
                      );
                      if (time != null) {
                        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setDialogState(() => closing = formatted);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC300), foregroundColor: const Color(0xFF2B1D0E)),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateCanteenFields({
                      'auto_timing_off': autoOff,
                      'opening_time': opening,
                      'closing_time': closing,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBankAccountDialog() {
    String bankName = '';
    String accNum = '';
    String ifsc = '';

    try {
      bankName = widget.canteenData?['bank_name'] as String? ?? '';
      accNum = widget.canteenData?['account_number'] as String? ?? '';
      ifsc = widget.canteenData?['ifsc_code'] as String? ?? '';
    } catch (_) {}

    final bankCtrl = TextEditingController(text: bankName);
    final accCtrl = TextEditingController(text: accNum);
    final ifscCtrl = TextEditingController(text: ifsc);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8E7),
          title: const Text('Bank Payout Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accCtrl,
                decoration: const InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ifscCtrl,
                decoration: const InputDecoration(labelText: 'IFSC Code'),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC300), foregroundColor: const Color(0xFF2B1D0E)),
              onPressed: () {
                Navigator.pop(context);
                _updateCanteenFields({
                  'bank_name': bankCtrl.text.trim(),
                  'account_number': accCtrl.text.trim(),
                  'ifsc_code': ifscCtrl.text.trim().toUpperCase(),
                });
              },
              child: const Text('Save Payout Info'),
            ),
          ],
        );
      },
    );
  }

  void _showMaxConcurrentLimitDialog() {
    int maxConcurrent = 10;
    try {
      maxConcurrent = widget.canteenData?['max_concurrent_orders'] as int? ?? 10;
    } catch (_) {}

    final ctrl = TextEditingController(text: maxConcurrent.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8E7),
          title: const Text('Order Processing Limit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set the maximum number of active in-progress orders you want to receive at a time.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Active Orders',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC300), foregroundColor: const Color(0xFF2B1D0E)),
              onPressed: () {
                final limit = int.tryParse(ctrl.text.trim());
                if (limit == null || limit <= 0) return;
                Navigator.pop(context);
                _updateCanteenFields({'max_concurrent_orders': limit});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canteenName = widget.canteenData?['name'] ?? 'Preorder Canteen';
    final canteenLocation = widget.canteenData?['location'] ?? 'Main Block';
    final imageUrl = widget.canteenData?['image_url'] as String?;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Settings Header ───────────────────────────────────────────────
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B1D0E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your vendor configuration',
                style: TextStyle(color: Color(0xFF8D7F70), fontSize: 14),
              ),
              const SizedBox(height: 24),

              // ── Vendor Profile Card ───────────────────────────────────────────
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFECE6DA)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _uploadProfilePhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFFFFF8E7),
                              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? const Icon(Icons.storefront, color: Color(0xFF2B1D0E), size: 30)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFC300),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 12, color: Color(0xFF2B1D0E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              canteenName,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2B1D0E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canteenLocation.isNotEmpty ? canteenLocation : 'Location unset',
                              style: const TextStyle(color: Color(0xFF8D7F70), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2B1D0E)),
                        onPressed: _showEditProfileDialog,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Timings & Working Hours ───────────────────────────────────────
              _buildSettingsGroupHeader('TIMING & HOURS'),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFECE6DA)),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.access_time,
                      title: 'Working Hours & Auto-Close',
                      subtitle: 'Configure daily timings and auto-ordering off toggle',
                      theme: theme,
                      onTap: _showTimingSettingsDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Operational Settings ──────────────────────────────────────────
              _buildSettingsGroupHeader('OPERATIONS'),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFECE6DA)),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.payments_outlined,
                      title: 'Payments & Payouts',
                      subtitle: 'Configure bank account details for merchant payouts',
                      theme: theme,
                      onTap: _showBankAccountDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    (() {
                      int maxConcurrent = 10;
                      try {
                        maxConcurrent = widget.canteenData?['max_concurrent_orders'] as int? ?? 10;
                      } catch (_) {}
                      return _buildSettingsTile(
                        icon: Icons.speed_outlined,
                        title: 'Order Processing Limit',
                        subtitle: 'Limit incoming orders to $maxConcurrent in-progress orders',
                        theme: theme,
                        onTap: _showMaxConcurrentLimitDialog,
                      );
                    })(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Logout Button ─────────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Sign Out of Store', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC300)),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF8D7F70),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFFFF8E7),
        child: Icon(icon, color: const Color(0xFF2B1D0E), size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF2B1D0E))),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8D7F70), fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8D7F70)),
      onTap: onTap,
    );
  }
}
