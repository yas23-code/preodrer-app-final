import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../canteen/screens/canteens_screen.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';
import '../../admin/screens/canteen_approvals_screen.dart';
import '../screens/registration_status_screen.dart';
import '../providers/role_provider.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == AppRole.superadmin) {
          return const CanteenApprovalsScreen();
        }
        if (role == AppRole.vendor) {
          return const VendorDashboardScreen();
        }
        
        // If they are mapped to customer, check if they have a pending/rejected registration
        final registrationAsync = ref.watch(myRegistrationProvider);
        return registrationAsync.when(
          data: (reg) {
            if (reg != null) {
              final status = reg['status'] as String? ?? 'pending';
              if (status == 'pending' || status == 'rejected') {
                return ShopRegistrationStatusScreen(
                  status: status,
                  rejectionReason: reg['rejection_reason'] as String?,
                );
              }
            }
            return const CanteensScreen();
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const CanteensScreen(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => const CanteensScreen(), // Default to customer on error
    );
  }
}
