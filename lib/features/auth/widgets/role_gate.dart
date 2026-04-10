import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../menu/screens/menu_screen.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';
import '../providers/role_provider.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(roleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == AppRole.vendor) {
          return const VendorDashboardScreen();
        }
        return const MenuScreen();
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => const MenuScreen(), // Default to customer on error
    );
  }
}
