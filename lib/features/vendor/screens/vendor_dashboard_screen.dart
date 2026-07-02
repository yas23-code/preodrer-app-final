import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/vendor_orders_provider.dart';
import '../../../core/supabase_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'manage_menu_screen.dart';
import 'vendor_coupons_screen.dart';
import 'vendor_settings_tab.dart';
import 'vendor_analytics_tab.dart';
import '../../canteen/providers/canteen_provider.dart';
import '../providers/vendor_menu_provider.dart';



class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  ConsumerState<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  bool? _isOpen;
  bool _isSaving = false;
  int _selectedTab = 0; // Desktop/Live Orders status filter: 0: In Progress, 1: Ready, 2: Completed
  int _selectedMobileTab = 0; // Mobile Bottom Nav: 0: Dashboard, 1: Orders, 2: Menu, 3: Analytics, 4: Settings
  final TextEditingController _pickupCodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _pickupCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSignOut() {
    ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _processCompletion({bool isQr = false}) async {
    try {
      final input = _pickupCodeController.text.trim().toUpperCase();
      if (input.isEmpty) return;

      final allOrders = ref.read(vendorOrdersProvider).value ?? [];
      final matchingOrders = allOrders.where((o) {
        if (o['raw_status'] != 'ready') return false;
        final pinVal = o['secretPin']?.toString() ?? (o['id'] as String).substring(0, 4).toUpperCase();
        return pinVal == input;
      }).toList();

      if (matchingOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isQr ? 'Invalid QR code. Please try again.' : 'The PIN was wrong or order is not Ready.')),
        );
        return;
      }
      
      final match = matchingOrders.first;
      
      await ref.read(vendorOrdersProvider.notifier).updateOrderStatus(match['id'], 'completed');
      _pickupCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Completed successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UI/Verification Error: $e')),
        );
      }
    }
  }

  void _showScannerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scan Order QR'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final code = barcode.rawValue;
                  if (code != null && code.isNotEmpty) {
                    Navigator.of(context).pop();
                    _pickupCodeController.text = code.toUpperCase();
                    _processCompletion(isQr: true);
                    break;
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleCanteenOpenState(bool val) async {
    final canteenAsync = ref.read(vendorCanteenProvider);
    final previousState = _isOpen;
    setState(() {
      _isOpen = val;
      _isSaving = true;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userAsync = ref.read(authControllerProvider);
      final userId = userAsync.value?.id;
      final canteenData = canteenAsync.value;

      if (userId == null) {
        throw Exception("User is not authenticated");
      }

      if (canteenData != null && canteenData['id'] != null) {
        await supabase
            .from('canteens')
            .update({'is_open': val})
            .eq('id', canteenData['id']);
      } else {
        await supabase.from('canteens').insert({
          'vendor_id': userId,
          'is_open': val,
          'name': 'My Canteen',
        });
      }

      ref.invalidate(vendorCanteenProvider);
      ref.invalidate(canteensProvider);
    } catch (e) {
      setState(() {
        _isOpen = previousState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showMaxOrdersLimitDialog(int currentLimit) {
    final ctrl = TextEditingController(text: currentLimit.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8E7),
          title: const Text('In-Progress Orders Limit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set the maximum number of in-progress orders you can handle at a time.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Orders Limit',
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
              onPressed: () async {
                final limit = int.tryParse(ctrl.text.trim());
                if (limit == null || limit <= 0) return;
                Navigator.pop(context);
                setState(() => _isSaving = true);
                try {
                  final canteenId = ref.read(vendorCanteenProvider).value?['id'];
                  if (canteenId != null) {
                    final supabase = ref.read(supabaseClientProvider);
                    await supabase
                        .from('canteens')
                        .update({'max_concurrent_orders': limit})
                        .eq('id', canteenId);
                    ref.invalidate(vendorCanteenProvider);
                  }
                } catch (e) {
                  if (mounted) {
                    final errorMsg = e.toString();
                    if (errorMsg.contains('max_concurrent_orders') || errorMsg.contains('PGRST204')) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFFFFF8E7),
                          title: const Text('Database Update Required', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E))),
                          content: const Text(
                            'The database schema is missing the concurrent orders limit column.\n\n'
                            'Please run the following SQL in your Supabase SQL Editor:\n\n'
                            'ALTER TABLE canteens \n'
                            'ADD COLUMN IF NOT EXISTS max_concurrent_orders INTEGER DEFAULT 10;'
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
                        SnackBar(content: Text('Failed to update limit: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } finally {
                  setState(() => _isSaving = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(Map<String, dynamic>? canteenData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFF8E7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: VendorSettingsTab(
              canteenData: canteenData,
              onSignOut: () {
                Navigator.pop(context);
                _handleSignOut();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canteenAsync = ref.watch(vendorCanteenProvider);
    
    return canteenAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error loading canteen: $err'))),
      data: (canteen) {
        if (canteen != null && canteen['banned'] == true) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF121212),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.block_flipped,
                    color: Color(0xFFDA291C),
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Canteen Banned / Deleted',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your canteen ID has been banned or deleted by the Super Admin.\nYou no longer have access to the vendor dashboard or incoming orders.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _handleSignOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDA291C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileShell();
            }
          },
        );
      },
    );
  }

  // ─── DESKTOP/WEB VIEW ───
  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final allOrders = ordersAsync.value ?? [];

    final canteenAsync = ref.watch(vendorCanteenProvider);
    final canteenName = canteenAsync.value?['name'] ?? 'GAURI CAFE';
    final canteenLocation = canteenAsync.value?['location'] ?? 'AB 2nd floor';

    if (_isOpen == null && canteenAsync.hasValue) {
      _isOpen = canteenAsync.value?['is_open'] as bool? ?? true;
    }

    final query = _searchController.text.trim().toLowerCase();
    
    final searchedOrders = allOrders.where((o) {
      final customer = (o['customerName'] as String? ?? '').toLowerCase();
      return customer.contains(query);
    }).toList();

    final filteredOrders = searchedOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      if (_selectedTab == 0) {
        return rawStatus == 'pending' || 
               rawStatus == 'confirmed' || 
               rawStatus == 'accepted' || 
               rawStatus == 'preparing' || 
               rawStatus == 'in_progress';
      }
      if (_selectedTab == 1) return rawStatus == 'ready';
      if (_selectedTab == 2) return rawStatus == 'completed' || rawStatus == 'rejected' || rawStatus == 'cancelled' || rawStatus == 'declined';
      return false;
    }).toList();

    final inProgressCount = searchedOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      return rawStatus == 'pending' || 
             rawStatus == 'confirmed' || 
             rawStatus == 'accepted' || 
             rawStatus == 'preparing' || 
             rawStatus == 'in_progress';
    }).length;

    final readyCount = searchedOrders.where((o) => (o['raw_status'] as String? ?? '') == 'ready').length;

    final completedCount = searchedOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      return rawStatus == 'completed' || rawStatus == 'rejected' || rawStatus == 'cancelled' || rawStatus == 'declined';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP NAVIGATION HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E7),
                border: Border(bottom: BorderSide(color: Color(0xFFECE6DA))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.fastfood_rounded, color: Color(0xFFDA291C), size: 18),
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'pre',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextSpan(
                              text: 'order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDA291C),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextSpan(
                              text: '.food',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFC300),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    height: 32,
                    width: 1.5,
                    color: const Color(0xFFECE6DA),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canteenName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B1D0E),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (canteenLocation.isNotEmpty)
                          Text(
                            canteenLocation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8D7F70),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (_isOpen ?? true) ? 'Open' : 'Closed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: (_isOpen ?? true) ? Colors.green[700] : const Color(0xFFDA291C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isOpen ?? true,
                        activeThumbColor: const Color(0xFFFFC300),
                        inactiveThumbColor: Colors.grey[400],
                        inactiveTrackColor: Colors.grey[200],
                        onChanged: _isSaving ? null : _toggleCanteenOpenState,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageMenuScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF2B1D0E), size: 18),
                    label: const Text(
                      'Manage Menu',
                      style: TextStyle(
                        color: Color(0xFF2B1D0E),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC300),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDesktopOutlinedButton(
                    label: 'Coupons',
                    icon: Icons.local_offer_outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VendorCouponsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDesktopOutlinedButton(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    onPressed: () => _showSettingsDialog(canteenAsync.value),
                  ),
                  const SizedBox(width: 8),
                  _buildDesktopOutlinedButton(
                    label: 'Sign Out',
                    icon: Icons.logout,
                    onPressed: _handleSignOut,
                  ),
                ],
              ),
            ),
            // ── MAIN BODY CONTENT ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFECE6DA)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Complete an Order',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2B1D0E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Scan student's QR code or enter pickup code manually",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8D7F70),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showScannerDialog,
                                icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2B1D0E)),
                                label: const Text(
                                  'Scan QR Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2B1D0E),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC300),
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: const [
                                  Expanded(child: Divider(color: Color(0xFFECE6DA))),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR ENTER MANUALLY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8D7F70),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Color(0xFFECE6DA))),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E7),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFECE6DA)),
                                      ),
                                      child: TextField(
                                        controller: _pickupCodeController,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter Pickup Code',
                                          hintStyle: TextStyle(color: Color(0xFFA59888), fontSize: 15),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF2B1D0E),
                                        ),
                                        keyboardType: TextInputType.text,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: () => _processCompletion(isQr: false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2B1D0E),
                                      side: const BorderSide(color: Color(0xFFFFC300), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                                    ),
                                    child: const Text(
                                      'Complete Order',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFECE6DA)),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => setState(() {}),
                                  decoration: const InputDecoration(
                                    hintText: 'Search by customer name...',
                                    hintStyle: TextStyle(color: Color(0xFFA59888), fontSize: 14),
                                    prefixIcon: Icon(Icons.search, color: Color(0xFF8D7F70)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  style: const TextStyle(color: Color(0xFF2B1D0E), fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDesktopPillTab(0, 'In Progress ($inProgressCount)'),
                                const SizedBox(width: 8),
                                _buildDesktopPillTab(1, 'Ready ($readyCount)'),
                                const SizedBox(width: 8),
                                _buildDesktopPillTab(2, 'Completed ($completedCount)'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (filteredOrders.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 280,
                            ),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              return _buildDesktopOrderCard(filteredOrders[index], theme, ref);
                            },
                          )
                        else
                          _buildDesktopEmptyState(ordersAsync),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF2B1D0E), size: 16),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2B1D0E),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFECE6DA)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDesktopPillTab(int index, String label) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFC300) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF2B1D0E) : const Color(0xFF7F664C),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopEmptyState(AsyncValue<List<Map<String, dynamic>>> ordersAsync) {
    if (ordersAsync.isLoading && !ordersAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC300))),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 40,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B1D0E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'New orders will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8D7F70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopOrderCard(Map<String, dynamic> order, ThemeData theme, WidgetRef ref) {
    final rawStatus = order['raw_status'] as String? ?? '';
    final orderId = order['id'] as String;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE6DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order['orderNumber'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order['type'],
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Text(
                order['amount'],
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2B1D0E)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFECE6DA)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer', style: TextStyle(color: Color(0xFF8D7F70), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    order['customerName'],
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2B1D0E)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Time / ETA', style: TextStyle(color: Color(0xFF8D7F70), fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(order['time'], style: const TextStyle(fontSize: 13, color: Color(0xFF2B1D0E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.access_time, size: 13, color: Color(0xFFDA291C)),
                      const SizedBox(width: 2),
                      Text(
                        order['eta'],
                        style: const TextStyle(color: Color(0xFFDA291C), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFECE6DA).withValues(alpha: 0.5)),
              ),
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF8D7F70)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (order['items_list'] as List<dynamic>? ?? []).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2B1D0E)),
                                ),
                                if (item['subtitle'] != null)
                                  Text(
                                    item['subtitle'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D7F70)),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (rawStatus == 'pending' || rawStatus == 'confirmed') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _promptDeclineReason(orderId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5D4037),
                      side: const BorderSide(color: Color(0xFFECE6DA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(vendorOrdersProvider.notifier).updateOrderStatus(orderId, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (rawStatus == 'accepted' || rawStatus == 'processing') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(vendorOrdersProvider.notifier).updateOrderStatus(orderId, 'ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Mark Ready', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── MOBILE SHELL WITH BOTTOM NAVIGATION BAR ───
  Widget _buildMobileShell() {
    final canteenAsync = ref.watch(vendorCanteenProvider);
    
    Widget bodyWidget;
    switch (_selectedMobileTab) {
      case 0:
        bodyWidget = _buildMobileDashboardView();
        break;
      case 1:
        bodyWidget = _buildMobileOrdersView();
        break;
      case 2:
        bodyWidget = const ManageMenuScreen();
        break;
      case 3:
        bodyWidget = const VendorAnalyticsTab();
        break;
      case 4:
        bodyWidget = VendorSettingsTab(
          canteenData: canteenAsync.value,
          onSignOut: _handleSignOut,
        );
        break;
      default:
        bodyWidget = _buildMobileDashboardView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: bodyWidget,
      floatingActionButton: (_selectedMobileTab == 0 || _selectedMobileTab == 1)
          ? FloatingActionButton(
              onPressed: _showScannerDialog,
              backgroundColor: const Color(0xFFFFC300),
              foregroundColor: const Color(0xFF2B1D0E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.qr_code_scanner, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedMobileTab,
        onTap: (index) => setState(() => _selectedMobileTab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF8B6B24), // dark gold/brown matching screenshot
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // Mobile Dashboard View (Screenshot 5)
  Widget _buildMobileDashboardView() {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final allOrders = ordersAsync.value ?? [];

    final canteenAsync = ref.watch(vendorCanteenProvider);
    final canteenName = canteenAsync.value?['name'] ?? 'GAURI CAFE';
    final canteenLocation = canteenAsync.value?['location'] ?? 'AB 2nd floor';

    if (_isOpen == null && canteenAsync.hasValue) {
      _isOpen = canteenAsync.value?['is_open'] as bool? ?? true;
    }

    final maxConcurrent = canteenAsync.value?['max_concurrent_orders'] as int? ?? 10;

    // Calculating Metrics
    final todayOrdersCount = allOrders.length;
    final todayRevenue = allOrders.where((o) => o['raw_status'] == 'completed').fold(0.0, (sum, o) {
      final amt = (o['amount'] as String).replaceAll('₹', '').replaceAll(',', '').trim();
      return sum + (double.tryParse(amt) ?? 0.0);
    });

    final pendingCount = allOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      return rawStatus == 'pending' || 
             rawStatus == 'confirmed' || 
             rawStatus == 'accepted' || 
             rawStatus == 'preparing' || 
             rawStatus == 'in_progress';
    }).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Canteen Header with toggle capsule
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFFC300).withValues(alpha: 0.15),
                  child: const Icon(Icons.storefront, color: Color(0xFF8B6B24), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canteenName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2B1D0E),
                        ),
                      ),
                      if (canteenLocation.isNotEmpty)
                        Text(
                          canteenLocation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8D7F70),
                          ),
                        ),
                    ],
                  ),
                ),
                // Styled OPEN/CLOSED toggle switch capsule (Screenshot 5)
                GestureDetector(
                  onTap: _isSaving ? null : () => _toggleCanteenOpenState(!(_isOpen ?? true)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isOpen ?? true) ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_isOpen ?? true) ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isOpen ?? true) ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (_isOpen ?? true) ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: (_isOpen ?? true) ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Horizontal Metric Cards (Screenshot 5)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDashboardMetricCard(
                    title: "Today's Orders",
                    value: todayOrdersCount.toString(),
                    icon: Icons.receipt_long,
                    color: const Color(0xFFFFA726), // Yellow/orange
                  ),
                  const SizedBox(width: 12),
                  _buildDashboardMetricCard(
                    title: "Today's Revenue",
                    value: '₹${todayRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments,
                    color: const Color(0xFF66BB6A), // Green
                  ),
                  const SizedBox(width: 12),
                  _buildDashboardMetricCard(
                    title: "Pending / Live (Limit: $maxConcurrent)",
                    value: '$pendingCount / $maxConcurrent',
                    icon: Icons.pending_actions,
                    color: const Color(0xFFEF5350), // Red
                    onTap: () {
                      _showMaxOrdersLimitDialog(maxConcurrent);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2B1D0E),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: [
                _buildGridActionBtn(
                  label: 'Manage Menu',
                  icon: Icons.restaurant_menu,
                  onTap: () => setState(() => _selectedMobileTab = 2),
                ),
                _buildGridActionBtn(
                  label: 'Coupons',
                  icon: Icons.local_offer_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VendorCouponsScreen()),
                    );
                  },
                ),
                _buildGridActionBtn(
                  label: 'Analytics',
                  icon: Icons.analytics,
                  onTap: () => setState(() => _selectedMobileTab = 3),
                ),
                _buildGridActionBtn(
                  label: 'Inventory',
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inventory setup coming soon!')),
                    );
                  },
                ),
                _buildGridActionBtn(
                  label: 'Settings',
                  icon: Icons.settings,
                  onTap: () => setState(() => _selectedMobileTab = 4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Busy Hour Alert
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFECE6DA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC300).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: Color(0xFFFFC300), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Busy Hour Alert',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2B1D0E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lunch rush expected between 12:30 PM and 1:45 PM today. Keep prep stations ready!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8D7F70),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFECE6DA)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF8B6B24), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B1D0E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Orders View (Screenshot 3)
  Widget _buildMobileOrdersView() {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final allOrders = ordersAsync.value ?? [];

    final query = _searchController.text.trim().toLowerCase();
    final searchedOrders = allOrders.where((o) {
      final customer = (o['customerName'] as String? ?? '').toLowerCase();
      final orderNo = (o['orderNumber'] as String? ?? '').toLowerCase();
      final pin = (o['secretPin'] as String? ?? '').toLowerCase();
      return customer.contains(query) || orderNo.contains(query) || pin.contains(query);
    }).toList();

    final filteredOrders = searchedOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      if (_selectedTab == 0) {
        return rawStatus == 'pending' || 
               rawStatus == 'confirmed' || 
               rawStatus == 'accepted' || 
               rawStatus == 'preparing' || 
               rawStatus == 'in_progress';
      }
      if (_selectedTab == 1) return rawStatus == 'ready';
      if (_selectedTab == 2) return rawStatus == 'completed' || rawStatus == 'rejected' || rawStatus == 'cancelled' || rawStatus == 'declined';
      return false;
    }).toList();

    // Tab counts for the headers
    final inProgressCount = searchedOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      return rawStatus == 'pending' || 
             rawStatus == 'confirmed' || 
             rawStatus == 'accepted' || 
             rawStatus == 'preparing' || 
             rawStatus == 'in_progress';
    }).length;

    final readyCount = searchedOrders.where((o) => (o['raw_status'] as String? ?? '') == 'ready').length;
    final historyCount = searchedOrders.where((o) {
      final rawStatus = o['raw_status'] as String? ?? '';
      return rawStatus == 'completed' || rawStatus == 'rejected' || rawStatus == 'cancelled' || rawStatus == 'declined';
    }).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Live Orders" Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Text(
              'Live Orders',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2B1D0E),
              ),
            ),
          ),

          // Filters Tab Row (Screenshot 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildMobileLiveOrderTab(0, 'In Progress', inProgressCount)),
                const SizedBox(width: 8),
                Expanded(child: _buildMobileLiveOrderTab(1, 'Ready', readyCount)),
                const SizedBox(width: 8),
                Expanded(child: _buildMobileLiveOrderTab(2, 'History', historyCount)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field: "Search by Customer, PIN or Order I..."
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECE6DA)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search by Customer, PIN or Order I...',
                  hintStyle: TextStyle(color: Color(0xFFA59888), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF8D7F70)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(color: Color(0xFF2B1D0E), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Complete Order Card (if Ready tab is selected, show at top of list)
          if (_selectedTab == 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE6DA)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Complete an Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showScannerDialog,
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2B1D0E)),
                      label: const Text('Scan QR Code', style: TextStyle(color: Color(0xFF2B1D0E), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFFC300), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFFECE6DA))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'OR',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8D7F70)),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFECE6DA))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFECE6DA)),
                            ),
                            child: TextField(
                              controller: _pickupCodeController,
                              decoration: const InputDecoration(
                                hintText: 'Enter pickup code',
                                hintStyle: TextStyle(color: Color(0xFFA59888)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E)),
                              keyboardType: TextInputType.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _processCompletion(isQr: false),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC300),
                            foregroundColor: const Color(0xFF2B1D0E),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Orders List / Empty State
          Expanded(
            child: filteredOrders.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 80.0),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildMobileLiveOrderCard(filteredOrders[index], ref);
                    },
                  )
                : _buildMobileEmptyState(ordersAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLiveOrderTab(int index, String label, int count) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFA726) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFFA726) : const Color(0xFFECE6DA),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF8D7F70),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLiveOrderCard(Map<String, dynamic> order, WidgetRef ref) {
    final rawStatus = order['raw_status'] as String? ?? '';
    final orderId = order['id'] as String;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: const Color(0xFFFFFDF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFECE6DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code, Type, Payment Tag, Price (Screenshot 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order['orderNumber'],
                        style: const TextStyle(color: Color(0xFF8B6B24), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order['type'],
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Paid',
                        style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Text(
                  order['amount'],
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2B1D0E)),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFECE6DA)),

            // Customer details & Timer (Screenshot 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CUSTOMER', style: TextStyle(color: Color(0xFF8D7F70), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      order['customerName'],
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF2B1D0E)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Placed ${order['time']}', style: const TextStyle(color: Color(0xFF8D7F70), fontSize: 10)),
                    const SizedBox(height: 2),
                    _VendorLiveEtaBadge(
                      scheduledTimeStr: order['eta_scheduled_time'] as String?,
                      fallbackEta: order['eta'] as String? ?? '',
                      rawStatus: order['raw_status'] as String? ?? '',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items Container (Screenshot 3: Beige styled item background)
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (order['items_list'] as List<dynamic>? ?? []).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFC300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2B1D0E)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Decline/Accept Buttons (Screenshot 3)
            if (rawStatus == 'pending' || rawStatus == 'confirmed') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _promptDeclineReason(orderId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC62828),
                        side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(vendorOrdersProvider.notifier).updateOrderStatus(orderId, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC300),
                        foregroundColor: const Color(0xFF2B1D0E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ] else if (rawStatus == 'accepted' || rawStatus == 'processing') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(vendorOrdersProvider.notifier).updateOrderStatus(orderId, 'ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC300),
                        foregroundColor: const Color(0xFF2B1D0E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Mark Ready', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileEmptyState(AsyncValue<List<Map<String, dynamic>>> ordersAsync) {
    if (ordersAsync.isLoading && !ordersAsync.hasValue) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC300)));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 32,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No pending orders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2B1D0E)),
          ),
          const SizedBox(height: 4),
          const Text(
            'New orders will appear here',
            style: TextStyle(fontSize: 12, color: Color(0xFF8D7F70)),
          ),
        ],
      ),
    );
  }

  Future<void> _promptDeclineReason(String orderId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Decline Order', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please enter a reason for declining this order:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Out of stock, Kitchen closed...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(context, text.isNotEmpty ? text : 'Not specified');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDA291C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Decline Order'),
            ),
          ],
        );
      },
    );

    if (reason != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(vendorOrdersProvider.notifier).updateOrderStatus(
            orderId,
            'declined',
            rejectionReason: reason,
          );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order declined successfully.'),
          backgroundColor: Color(0xFFDA291C),
        ),
      );
    }
  }
}

class _VendorLiveEtaBadge extends StatefulWidget {
  final String? scheduledTimeStr;
  final String fallbackEta;
  final String rawStatus;

  const _VendorLiveEtaBadge({
    required this.scheduledTimeStr,
    required this.fallbackEta,
    required this.rawStatus,
  });

  @override
  State<_VendorLiveEtaBadge> createState() => _VendorLiveEtaBadgeState();
}

class _VendorLiveEtaBadgeState extends State<_VendorLiveEtaBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For completed/declined statuses, don't show countdown
    if (widget.rawStatus == 'completed' ||
        widget.rawStatus == 'delivered' ||
        widget.rawStatus == 'declined' ||
        widget.rawStatus == 'rejected' ||
        widget.rawStatus == 'cancelled') {
      return const SizedBox.shrink();
    }

    String displayText;
    if (widget.scheduledTimeStr != null) {
      final scheduledTime = DateTime.tryParse(widget.scheduledTimeStr!)?.toLocal();
      if (scheduledTime != null) {
        final remaining = scheduledTime.difference(DateTime.now()).inMinutes;
        displayText = remaining > 0 ? 'Est. $remaining mins' : 'Ready soon';
      } else {
        displayText = widget.fallbackEta;
      }
    } else {
      displayText = widget.fallbackEta;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, size: 12, color: Color(0xFFDA291C)),
        const SizedBox(width: 4),
        Text(
          displayText,
          style: const TextStyle(
            color: Color(0xFFDA291C),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
