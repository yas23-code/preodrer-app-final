import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/refunds_provider.dart';
import '../../../shared/utils/formatters.dart';

class PendingRefundsView extends ConsumerStatefulWidget {
  const PendingRefundsView({super.key});

  @override
  ConsumerState<PendingRefundsView> createState() => _PendingRefundsViewState();
}

class _PendingRefundsViewState extends ConsumerState<PendingRefundsView> {
  final _searchCtrl = TextEditingController();
  final _studentCtrl = TextEditingController();
  final _orderIdCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _studentCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  // Safe extraction helpers
  Map<String, dynamic>? _extractProfile(Map<String, dynamic> order) {
    try {
      final data = order['profiles'];
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data.first);
    } catch (_) {}
    return null;
  }

  String _extractCanteenName(Map<String, dynamic> order) {
    try {
      final data = order['canteens'];
      if (data is Map) return data['name']?.toString() ?? '—';
    } catch (_) {}
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(refundsProvider);
    final stats = ref.watch(refundsStatsProvider);
    final refunds = ref.watch(filteredRefundsProvider);

    // Build list items
    final List<Widget> items = [];

    // 1. Red Alert Banner
    items.add(_buildRedAlertBanner(stats));
    items.add(const SizedBox(height: 16));

    // 2. Stats Row
    items.add(_buildStatsRow(stats));
    items.add(const SizedBox(height: 16));

    // 3. Search Bar
    items.add(_buildSearchBar());
    items.add(const SizedBox(height: 12));

    // 4. Filter Chips Row
    items.add(_buildFilterChips(state));
    items.add(const SizedBox(height: 16));

    // 5. Section Header
    items.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state.statusFilter == 'pending'
                ? 'Pending Refunds (${refunds.length})'
                : state.statusFilter == 'processed'
                    ? 'Processed Refunds (${refunds.length})'
                    : 'All Refunds (${refunds.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDA291C),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => ref.read(refundsProvider.notifier).fetchRefundOrders(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 20, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    items.add(const SizedBox(height: 12));

    // 6. Content: Error / Empty / Cards
    if (state.errorMessage != null) {
      items.add(_buildErrorState(state.errorMessage!));
    } else if (refunds.isEmpty && !state.isLoading) {
      items.add(_buildEmptyState());
    } else {
      for (final order in refunds) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildRefundCard(order),
        ));
      }
    }

    // Bottom padding
    items.add(const SizedBox(height: 24));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  // ── Red Alert Banner ───────────────────────────────────────────
  Widget _buildRedAlertBanner(RefundsStats stats) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDA291C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDA291C).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PENDING REFUNDS AUDIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stats.totalPendingCount} Pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Ensure all rejected orders are manually refunded or processed through Razorpay, then mark them as processed here to maintain audit compliance.',
            style: TextStyle(
              color: Color(0xFFFFECEB),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────
  Widget _buildStatsRow(RefundsStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending Amount',
            formatCurrency(stats.totalPendingAmount),
            const Color(0xFFDA291C),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Today Rejected',
            '${stats.todayRejectedCount}',
            const Color(0xFFFFC300),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Month Rejected',
            '${stats.monthRejectedCount}',
            Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => ref.read(refundsProvider.notifier).setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search order ID, student, email or canteen...',
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDA291C), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────
  Widget _buildFilterChips(RefundsState state) {
    return Row(
      children: [
        const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
        const SizedBox(width: 4),
        _buildChip('Pending', 'pending', state.statusFilter),
        const SizedBox(width: 6),
        _buildChip('Processed', 'processed', state.statusFilter),
        const SizedBox(width: 6),
        _buildChip('All', 'all', state.statusFilter),
        const Spacer(),
        GestureDetector(
          onTap: () => _showFilterSheet(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[700])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String value, String currentValue) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => ref.read(refundsProvider.notifier).setStatusFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDA291C) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ── Advanced Filter Sheet ──────────────────────────────────────
  void _showFilterSheet(BuildContext context, RefundsState state) {
    final canteens = state.allOrders
        .map((o) {
          final d = o['canteens'];
          return d is Map ? d['name'] as String? : null;
        })
        .where((name) => name != null)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Advanced Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
                    const SizedBox(height: 16),

                    // Canteen Filter
                    const Text('Filter by Canteen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildChipForSheet('All Canteens', 'all', state.canteenFilter, (val) {
                          ref.read(refundsProvider.notifier).setCanteenFilter(val);
                          setModalState(() {});
                        }),
                        for (final c in canteens)
                          _buildChipForSheet(c!, c, state.canteenFilter, (val) {
                            ref.read(refundsProvider.notifier).setCanteenFilter(val);
                            setModalState(() {});
                          }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Student Name/Email Filter
                    const Text('Student Name / Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _studentCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. John Doe',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => ref.read(refundsProvider.notifier).setStudentFilter(val),
                    ),
                    const SizedBox(height: 16),

                    // Order ID Filter
                    const Text('Order ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _orderIdCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search exact order ID...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => ref.read(refundsProvider.notifier).setOrderIdFilter(val),
                    ),
                    const SizedBox(height: 16),

                    // Date Range
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: ctx,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                          initialDateRange: state.dateRangeFilter,
                        );
                        if (picked != null) {
                          ref.read(refundsProvider.notifier).setDateRangeFilter(picked);
                          setModalState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.dateRangeFilter == null
                                  ? 'Select Date Range'
                                  : '${DateFormat.yMMMd().format(state.dateRangeFilter!.start)} - ${DateFormat.yMMMd().format(state.dateRangeFilter!.end)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (state.dateRangeFilter != null)
                              GestureDetector(
                                onTap: () {
                                  ref.read(refundsProvider.notifier).clearDateRangeFilter();
                                  setModalState(() {});
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              )
                            else
                              const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Apply
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDA291C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChipForSheet(String label, String value, String current, ValueChanged<String> onTap) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDA291C) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ── Refund Card ────────────────────────────────────────────────
  Widget _buildRefundCard(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? '—';
    final amount = (order['total_amount'] as num? ?? 0.0).toDouble();
    final canteenName = _extractCanteenName(order);
    final rejectionReason = order['rejection_reason']?.toString() ?? 'Not specified';
    final refundStatus = order['refund_status']?.toString() ?? 'pending';

    final profile = _extractProfile(order);
    final studentName = profile?['name']?.toString() ?? profile?['full_name']?.toString() ?? '—';
    final email = profile?['email']?.toString() ?? '—';
    final phone = profile?['phone']?.toString() ?? '—';

    final createdAtStr = order['created_at']?.toString();
    String formattedTime = '—';
    if (createdAtStr != null) {
      final d = DateTime.tryParse(createdAtStr);
      if (d != null) formattedTime = DateFormat.yMMMd().add_jm().format(d.toLocal());
    }

    final isPending = refundStatus == 'pending';
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFDA291C).withOpacity(0.5) : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Student Name & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatCurrency(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isPending ? const Color(0xFFDA291C) : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2: Order ID + Copy
          Row(
            children: [
              Text(
                'Order ID: #$shortId',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: orderId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order ID copied'), duration: Duration(seconds: 1)),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFFF5F5) : const Color(0xFFf0FFF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPending ? 'PENDING' : 'PROCESSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPending ? const Color(0xFFDA291C) : Colors.green,
                  ),
                ),
              ),
            ],
          ),

          Divider(height: 20, thickness: 1, color: Colors.grey[200]),

          // Detail rows
          _infoRow(Icons.storefront_rounded, 'Canteen', canteenName),
          const SizedBox(height: 5),
          _infoRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: 5),
          _infoRow(Icons.phone_outlined, 'Phone', phone),
          const SizedBox(height: 5),
          _infoRow(Icons.access_time_rounded, 'Rejected', formattedTime),
          const SizedBox(height: 5),
          _infoRow(Icons.error_outline_rounded, 'Reason', rejectionReason, isAlert: true),

          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => _showOrderDetailsDialog(order),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                ),
              ),
              const Spacer(),
              if (isPending)
                GestureDetector(
                  onTap: () => _processRefund(orderId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA291C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Mark Refund Processed',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    const Text('Processed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isAlert = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: isAlert ? const Color(0xFFDA291C) : Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isAlert ? const Color(0xFFDA291C) : Colors.black45),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isAlert ? const Color(0xFFDA291C) : Colors.black87,
              fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // ── Process Refund ─────────────────────────────────────────────
  Future<void> _processRefund(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Refund', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Mark this refund as processed? This action will archive this pending refund.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDA291C), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(refundsProvider.notifier).markRefundAsProcessed(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Refund marked as processed.' : 'Failed to update. Try again.'),
          backgroundColor: success ? Colors.green : const Color(0xFFDA291C),
        ),
      );
    }
  }

  // ── Order Details Dialog ───────────────────────────────────────
  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    final profile = _extractProfile(order);
    final studentName = profile?['name']?.toString() ?? profile?['full_name']?.toString() ?? '—';
    final email = profile?['email']?.toString() ?? '—';
    final phone = profile?['phone']?.toString() ?? '—';
    final canteenName = _extractCanteenName(order);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refund Audit Details', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        content: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(110),
              1: FlexColumnWidth(),
            },
            children: [
              _tableRow('Order ID', order['id']?.toString()),
              _tableRow('Student', studentName),
              _tableRow('Email', email),
              _tableRow('Phone', phone),
              _tableRow('Canteen', canteenName),
              _tableRow('Status', order['refund_status']?.toString().toUpperCase()),
              _tableRow('Reason', order['rejection_reason']?.toString()),
              _tableRow('Amount', formatCurrency((order['total_amount'] as num? ?? 0).toDouble())),
              if (order['refund_processed_at'] != null)
                _tableRow('Processed At', DateFormat.yMMMd().add_jm().format(DateTime.parse(order['refund_processed_at']))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String label, dynamic value) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54, fontSize: 12)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(value?.toString() ?? '—', style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ),
    ]);
  }

  // ── Empty / Error States ───────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No pending refunds found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDA291C).withOpacity(0.2)),
      ),
      child: Text('Error: $error', style: const TextStyle(color: Color(0xFFDA291C), fontSize: 14)),
    );
  }
}
