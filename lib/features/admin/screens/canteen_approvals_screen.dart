import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/canteen_approvals_provider.dart';
import '../providers/refunds_provider.dart';
import '../widgets/pending_refunds_view.dart';
import '../widgets/income_analytics_view.dart';
import '../widgets/daily_collection_view.dart';
import '../widgets/admin_search_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme.dart';

class CanteenApprovalsScreen extends ConsumerStatefulWidget {
  const CanteenApprovalsScreen({super.key});

  @override
  ConsumerState<CanteenApprovalsScreen> createState() =>
      _CanteenApprovalsScreenState();
}

class _CanteenApprovalsScreenState
    extends ConsumerState<CanteenApprovalsScreen> {
  int _currentTabIndex = 0;

  void _handleSignOut() {
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final refundsStats = ref.watch(refundsStatsProvider);

    return Theme(
      data: PreorderTheme.light(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Super Admin Panel',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.black54),
              onPressed: _handleSignOut,
              tooltip: 'Sign Out',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTab(0, 'Approvals', Icons.verified_rounded),
                    _buildTab(
                      1,
                      'Refunds',
                      Icons.currency_rupee_rounded,
                      badgeCount: refundsStats.totalPendingCount,
                    ),
                    _buildTab(2, 'Analytics', Icons.bar_chart_rounded),
                    _buildTab(3, 'Collection', Icons.today_rounded),
                    _buildTab(4, 'Search', Icons.search_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _currentTabIndex == 0
            ? const _CanteenApprovalsTab()
            : _currentTabIndex == 1
                ? const PendingRefundsView()
                : _currentTabIndex == 2
                    ? const IncomeAnalyticsView()
                    : _currentTabIndex == 3
                        ? const DailyCollectionView()
                        : const AdminSearchView(),
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon,
      {int badgeCount = 0}) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? const Color(0xFFDA291C)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color:
                    isSelected ? const Color(0xFFDA291C) : Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? const Color(0xFFDA291C) : Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDA291C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Canteen Approvals Tab ──────────────────────────────────────────

class _CanteenApprovalsTab extends ConsumerStatefulWidget {
  const _CanteenApprovalsTab();

  @override
  ConsumerState<_CanteenApprovalsTab> createState() =>
      _CanteenApprovalsTabState();
}

class _CanteenApprovalsTabState extends ConsumerState<_CanteenApprovalsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canteenApprovalsProvider);
    final stats = ref.watch(approvalsStatsProvider);
    final registrations = ref.watch(filteredRegistrationsProvider);

    final List<Widget> items = [];

    // Stats Row
    items.add(_buildStatsRow(stats));
    items.add(const SizedBox(height: 16));

    // Search Bar
    items.add(_buildSearchBar(state));
    items.add(const SizedBox(height: 16));

    // Header
    items.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pending Approvals (${registrations.length})',
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
                        strokeWidth: 2, color: Color(0xFFDA291C)),
                  ),
                ),
              GestureDetector(
                onTap: () =>
                    ref.read(canteenApprovalsProvider.notifier).fetchRegistrations(),
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

    // Content
    if (state.errorMessage != null) {
      items.add(_buildErrorState(state.errorMessage!));
    } else if (registrations.isEmpty && !state.isLoading) {
      items.add(_buildEmptyState());
    } else {
      for (final reg in registrations) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildRegistrationCard(reg),
        ));
      }
    }

    items.add(const SizedBox(height: 24));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildStatsRow(ApprovalsStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Pending', '${stats.totalPending}', const Color(0xFFDA291C)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('Approved Today', '${stats.approvedToday}', Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('Rejected Today', '${stats.rejectedToday}', Colors.orange),
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
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CanteenApprovalsState state) {
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
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (val) =>
                ref.read(canteenApprovalsProvider.notifier).setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Search canteen, owner, or email...',
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
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[600])),
              const SizedBox(width: 6),
              _buildFilterChip('All', 'all', state.dateFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Today', 'today', state.dateFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Week', 'week', state.dateFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Month', 'month', state.dateFilter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => ref.read(canteenApprovalsProvider.notifier).setDateFilter(value),
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

  Widget _buildRegistrationCard(Map<String, dynamic> reg) {
    final canteenName = reg['canteen_name']?.toString() ?? '—';
    final ownerName = reg['owner_name']?.toString() ?? '—';
    final email = reg['email']?.toString() ?? '—';
    final phone = reg['phone']?.toString() ?? '—';
    final location = reg['location']?.toString() ?? '—';
    final createdAtStr = reg['created_at']?.toString();
    String formattedTime = '—';
    if (createdAtStr != null) {
      final d = DateTime.tryParse(createdAtStr);
      if (d != null) formattedTime = DateFormat.yMMMd().add_jm().format(d.toLocal());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDA291C).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  canteenName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'Poppins'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFDA291C))),
              ),
            ],
          ),
          Divider(height: 20, thickness: 1, color: Colors.grey[200]),
          _infoRow(Icons.person_rounded, 'Owner', ownerName),
          const SizedBox(height: 5),
          _infoRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: 5),
          _infoRow(Icons.phone_outlined, 'Phone', phone),
          const SizedBox(height: 5),
          _infoRow(Icons.location_on_outlined, 'Location', location),
          const SizedBox(height: 5),
          _infoRow(Icons.access_time_rounded, 'Applied', formattedTime),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showRejectDialog(reg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _approveCanteen(reg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black45)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ),
      ],
    );
  }

  Future<void> _approveCanteen(Map<String, dynamic> reg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Approval', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Approve "${reg['canteen_name']}" as a vendor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await ref.read(canteenApprovalsProvider.notifier).approveCanteen(reg);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Canteen approved!' : 'Failed to approve.'),
          backgroundColor: success ? Colors.green : const Color(0xFFDA291C),
        ),
      );
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> reg) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Registration', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "${reg['canteen_name']}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDA291C), foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final reason = reasonCtrl.text.trim().isEmpty ? 'No reason provided' : reasonCtrl.text.trim();
      final success = await ref.read(canteenApprovalsProvider.notifier).rejectCanteen(reg['id'], reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Registration rejected.' : 'Failed to reject.'),
          backgroundColor: success ? Colors.orange : const Color(0xFFDA291C),
        ),
      );
    }
    reasonCtrl.dispose();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No pending approvals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
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
