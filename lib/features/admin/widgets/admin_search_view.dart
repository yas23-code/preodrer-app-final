import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_search_provider.dart';
import '../../../shared/utils/formatters.dart';

class AdminSearchView extends ConsumerStatefulWidget {
  const AdminSearchView({super.key});

  @override
  ConsumerState<AdminSearchView> createState() => _AdminSearchViewState();
}

class _AdminSearchViewState extends ConsumerState<AdminSearchView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch initial list when module is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSearchProvider.notifier).performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSearchProvider);
    final notifier = ref.read(adminSearchProvider.notifier);

    // If a detail profile is selected, show that profile view instead
    if (state.selectedStudent != null) {
      return _StudentProfileView(
        student: state.selectedStudent!,
        stats: state.selectedStudentStats ?? {'totalOrders': 0, 'totalSpent': 0.0},
        orders: state.selectedStudentOrders,
        onBack: () => notifier.selectStudent(null),
        onToggleBan: (currentStatus) => _showBanStudentDialog(context, notifier, state.selectedStudent!, currentStatus),
      );
    }

    if (state.selectedCanteen != null) {
      return _CanteenProfileView(
        canteen: state.selectedCanteen!,
        stats: state.selectedCanteenStats ?? {
          'totalOrders': 0,
          'earnings': 0.0,
          'pending': 0,
          'ready': 0,
          'completed': 0,
          'ordersByDate': <Map<String, dynamic>>[]
        },
        onBack: () => notifier.selectCanteen(null),
        onToggleBan: (currentStatus) => _showBanCanteenDialog(context, notifier, state.selectedCanteen!, currentStatus),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Search Title
              const Text(
                'Global Search',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search and manage students and canteens instantly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),

              // Search Text Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setQuery,
                  decoration: InputDecoration(
                    hintText: state.activeTab == 'students'
                        ? 'Search by name, email, phone, or Student ID...'
                        : 'Search by canteen name, vendor email, phone, location...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      label: 'Students',
                      isActive: state.activeTab == 'students',
                      icon: Icons.school_rounded,
                      onTap: () => notifier.setTab('students'),
                    ),
                    _buildTabButton(
                      label: 'Canteens',
                      isActive: state.activeTab == 'canteens',
                      icon: Icons.storefront_rounded,
                      onTap: () => notifier.setTab('canteens'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner if any
              if (state.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: Colors.red[800], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Results Section
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(color: Color(0xFFDA291C)),
                  ),
                )
              else if (state.activeTab == 'students')
                _buildStudentsList(state.students, notifier)
              else
                _buildCanteensList(state.canteens, notifier),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? const Color(0xFFDA291C) : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                  color: isActive ? const Color(0xFFDA291C) : Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> students, AdminSearchNotifier notifier) {
    if (students.isEmpty) {
      return _buildEmptyState('No students found', 'Try refining your search keyword.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final stu = students[index];
        final isBanned = stu['banned'] == true;
        final studentId = stu['student_id'] as String? ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            onTap: () => notifier.selectStudent(stu),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    stu['name'] as String? ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                  ),
                ),
                if (isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'BANNED',
                      style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stu['email'] as String? ?? 'No Email',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'ID: $studentId',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (stu['role'] as String? ?? 'student').toUpperCase(),
                          style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildCanteensList(List<Map<String, dynamic>> canteens, AdminSearchNotifier notifier) {
    if (canteens.isEmpty) {
      return _buildEmptyState('No canteens found', 'Try refining your search keyword.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: canteens.length,
      itemBuilder: (context, index) {
        final canteen = canteens[index];
        final isBanned = canteen['banned'] == true;
        final isOpen = canteen['is_open'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            onTap: () => notifier.selectCanteen(canteen),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    canteen['name'] as String? ?? 'No Canteen Name',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                  ),
                ),
                if (isBanned) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'BANNED',
                      style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isOpen ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: Text(
                    isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      color: isOpen ? Colors.green[700] : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          canteen['email'] as String? ?? 'No Email',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        canteen['location'] as String? ?? 'No Location',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showBanStudentDialog(BuildContext context, AdminSearchNotifier notifier, Map<String, dynamic> student, bool currentBannedStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentBannedStatus ? 'Unban Student' : 'Ban Student'),
        content: Text(
          currentBannedStatus
              ? 'Are you sure you want to restore access for ${student['name']}?'
              : 'Are you sure you want to ban ${student['name']}? They will not be able to log in or place orders.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentBannedStatus ? Colors.green : const Color(0xFFDA291C),
              foregroundColor: Colors.white,
            ),
            child: Text(currentBannedStatus ? 'Unban' : 'Ban'),
            onPressed: () async {
              Navigator.pop(context);
              final success = await notifier.toggleBanStudent(student['id'] as String, currentBannedStatus);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      currentBannedStatus
                          ? 'Student access restored successfully.'
                          : 'Student banned successfully.',
                    ),
                    backgroundColor: currentBannedStatus ? Colors.green : Colors.black87,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBanCanteenDialog(BuildContext context, AdminSearchNotifier notifier, Map<String, dynamic> canteen, bool currentBannedStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentBannedStatus ? 'Unban Canteen' : 'Ban Canteen'),
        content: Text(
          currentBannedStatus
              ? 'Are you sure you want to restore access for ${canteen['name']}?'
              : 'Are you sure you want to ban ${canteen['name']}? They will be locked out and cannot receive new orders.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentBannedStatus ? Colors.green : const Color(0xFFDA291C),
              foregroundColor: Colors.white,
            ),
            child: Text(currentBannedStatus ? 'Unban' : 'Ban'),
            onPressed: () async {
              Navigator.pop(context);
              final success = await notifier.toggleBanCanteen(canteen['id'] as String, currentBannedStatus);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      currentBannedStatus
                          ? 'Canteen access restored successfully.'
                          : 'Canteen banned successfully.',
                    ),
                    backgroundColor: currentBannedStatus ? Colors.green : Colors.black87,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── STUDENT PROFILE VIEW ──────────────────────────────────────────
class _StudentProfileView extends StatelessWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> orders;
  final VoidCallback onBack;
  final Function(bool) onToggleBan;

  const _StudentProfileView({
    required this.student,
    required this.stats,
    required this.orders,
    required this.onBack,
    required this.onToggleBan,
  });

  @override
  Widget build(BuildContext context) {
    final isBanned = student['banned'] == true;
    final createdAtStr = student['created_at'] as String?;
    final joinedDate = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    final formattedJoined = joinedDate != null ? DateFormat('MMM dd, yyyy').format(joinedDate) : 'N/A';
    final studentId = student['student_id'] as String? ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.04),
                  elevation: 4,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Student Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        student['name'] as String? ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBanned ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isBanned ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Text(
                        isBanned ? 'BANNED' : 'ACTIVE',
                        style: TextStyle(
                          color: isBanned ? Colors.red[700] : Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.email_outlined, 'Email', student['email'] as String? ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, 'Phone', student['phone'] as String? ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.badge_outlined, 'Student ID', studentId),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today_outlined, 'Joined Date', formattedJoined),
                const SizedBox(height: 20),

                // Ban Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBanned ? Colors.green[600] : const Color(0xFFDA291C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(isBanned ? Icons.check_circle_outline_rounded : Icons.block_flipped),
                    label: Text(
                      isBanned ? 'Unban Student' : 'Ban Student',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins'),
                    ),
                    onPressed: () => onToggleBan(isBanned),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  '${stats['totalOrders']}',
                  Icons.receipt_long_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Spent',
                  formatCurrency(stats['totalSpent'] as double? ?? 0.0),
                  Icons.currency_rupee_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Order History
          const Text(
            'Order History (Read-Only)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'No orders placed by this student.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final oDateStr = order['created_at'] as String?;
                final oDate = oDateStr != null ? DateTime.tryParse(oDateStr) : null;
                final oDateFmt = oDate != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(oDate) : 'N/A';
                final canteenMap = order['canteens'] as Map<String, dynamic>?;
                final canteenName = canteenMap?['name'] as String? ?? 'Acktron Canteen';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                canteenName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                oDateFmt,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency((order['total_amount'] as num?)?.toDouble() ?? 0.0),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            _buildMiniStatusBadge(order['status'] as String? ?? 'unknown'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusBadge(String status) {
    final norm = status.toLowerCase();
    Color bg = Colors.grey[100]!;
    Color fg = Colors.grey[600]!;

    if (norm == 'completed' || norm == 'delivered') {
      bg = Colors.green[50]!;
      fg = Colors.green[700]!;
    } else if (norm == 'ready') {
      bg = Colors.purple[50]!;
      fg = Colors.purple[700]!;
    } else if (norm == 'pending' || norm == 'confirmed') {
      bg = Colors.orange[50]!;
      fg = Colors.orange[700]!;
    } else if (norm == 'accepted' || norm == 'preparing' || norm == 'in_progress') {
      bg = Colors.blue[50]!;
      fg = Colors.blue[700]!;
    } else if (norm == 'cancel' || norm == 'rejected' || norm == 'declined') {
      bg = Colors.red[50]!;
      fg = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── CANTEEN PROFILE VIEW ──────────────────────────────────────────
class _CanteenProfileView extends StatelessWidget {
  final Map<String, dynamic> canteen;
  final Map<String, dynamic> stats;
  final VoidCallback onBack;
  final Function(bool) onToggleBan;

  const _CanteenProfileView({
    required this.canteen,
    required this.stats,
    required this.onBack,
    required this.onToggleBan,
  });

  @override
  Widget build(BuildContext context) {
    final isBanned = canteen['banned'] == true;
    final isOpen = canteen['is_open'] == true;
    final createdAtStr = canteen['created_at'] as String?;
    final regDate = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    final formattedReg = regDate != null ? DateFormat('MMM dd, yyyy').format(regDate) : 'N/A';

    final ordersByDate = stats['ordersByDate'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.04),
                  elevation: 4,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Canteen Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Canteen Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        canteen['name'] as String? ?? 'No Canteen Name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBanned) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'BANNED',
                              style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isOpen ? Colors.green.shade200 : Colors.grey.shade300),
                          ),
                          child: Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: isOpen ? Colors.green[700] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.email_outlined, 'Vendor Email', canteen['email'] as String? ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, 'Phone', canteen['phone'] as String? ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, 'Location', canteen['location'] as String? ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today_outlined, 'Registration Date', formattedReg),
                const SizedBox(height: 20),

                // Ban Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBanned ? Colors.green[600] : const Color(0xFFDA291C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(isBanned ? Icons.check_circle_outline_rounded : Icons.block_flipped),
                    label: Text(
                      isBanned ? 'Unban Canteen' : 'Ban Canteen',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins'),
                    ),
                    onPressed: () => onToggleBan(isBanned),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Total Earnings & Orders Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Earnings',
                  formatCurrency(stats['earnings'] as double? ?? 0.0),
                  Icons.currency_rupee_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  '${stats['totalOrders']}',
                  Icons.receipt_long_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detailed Status Counts Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCountCol('Pending', '${stats['pending']}', Colors.orange),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildStatusCountCol('Ready', '${stats['ready']}', Colors.purple),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildStatusCountCol('Completed', '${stats['completed']}', Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Orders-by-Date Section
          const Text(
            'Orders by Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          if (ordersByDate.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'No orders registered on this canteen.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Poppins'),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Orders',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Poppins'),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Revenue',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Poppins'),
                    ),
                    numeric: true,
                  ),
                ],
                rows: ordersByDate.map<DataRow>((day) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        day['date'] as String? ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      )),
                      DataCell(Text(
                        '${day['ordersCount']}',
                        style: const TextStyle(fontSize: 13),
                      )),
                      DataCell(Text(
                        formatCurrency(day['revenue'] as double? ?? 0.0),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.green),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCountCol(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
