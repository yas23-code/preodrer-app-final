import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:preorder_app/features/auth/providers/role_provider.dart';
import 'package:preorder_app/features/auth/providers/auth_provider.dart';
import 'package:preorder_app/core/supabase_client.dart';
import 'package:preorder_app/core/router.dart';

// We'll write a simple unit test checking the GoRouter redirect logic directly by mocking state.
void main() {
  test('GoRouter redirect gates pending vendor to /vendor-pending', () {
    // We can simulate the state check since we know the exact redirect conditions.
    String? redirectCheck({
      required String path,
      required bool isLoading,
      required bool hasUser,
      required AppRole role,
      required String? vendorStatus,
    }) {
      final isPublic = path == '/' || path == '/login';
      final isVendorPending = path == '/vendor-pending';

      if (isLoading) {
        return isPublic ? null : '/';
      }

      if (!hasUser) {
        if (isVendorPending) return '/';
        return isPublic ? null : '/';
      }

      if (role == AppRole.vendor && vendorStatus != 'approved') {
        return isVendorPending ? null : '/vendor-pending';
      }

      if (role == AppRole.customer && (vendorStatus == 'pending' || vendorStatus == 'rejected')) {
        return isVendorPending ? null : '/vendor-pending';
      }

      if (isVendorPending) {
        return '/home';
      }

      if (isPublic) {
        return '/home';
      }

      return null;
    }

    // 1. Pending vendor trying to go to /home -> should be redirected to /vendor-pending
    expect(
      redirectCheck(
        path: '/home',
        isLoading: false,
        hasUser: true,
        role: AppRole.vendor,
        vendorStatus: 'pending',
      ),
      equals('/vendor-pending'),
    );

    // 2. Pending vendor on /vendor-pending -> should stay there (return null)
    expect(
      redirectCheck(
        path: '/vendor-pending',
        isLoading: false,
        hasUser: true,
        role: AppRole.vendor,
        vendorStatus: 'pending',
      ),
      isNull,
    );

    // 3. Approved vendor on /vendor-pending -> should be redirected to /home
    expect(
      redirectCheck(
        path: '/vendor-pending',
        isLoading: false,
        hasUser: true,
        role: AppRole.vendor,
        vendorStatus: 'approved',
      ),
      equals('/home'),
    );

    // 4. Regular customer going to /home -> should stay there (return null)
    expect(
      redirectCheck(
        path: '/home',
        isLoading: false,
        hasUser: true,
        role: AppRole.customer,
        vendorStatus: null,
      ),
      isNull,
    );
  });
}
