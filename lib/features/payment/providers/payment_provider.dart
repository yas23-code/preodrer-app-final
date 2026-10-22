import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';

final paymentControllerProvider = Provider<PaymentController>((ref) {
  return PaymentController(ref);
});

/// Data returned by [PaymentController.createCashfreeSession] after the
/// Supabase edge function creates the order on Cashfree's server.
class CashfreeSessionData {
  final String appOrderId;       // Our own UUID from `orders` table
  final String cfOrderId;        // Cashfree's cf_order_id
  final String paymentSessionId; // Used to open the Cashfree SDK payment sheet

  const CashfreeSessionData({
    required this.appOrderId,
    required this.cfOrderId,
    required this.paymentSessionId,
  });
}

class PaymentController {
  final Ref ref;

  PaymentController(this.ref);

  /// Calls the `create-cashfree-order` Supabase Edge Function.
  ///
  /// The edge function:
  ///   1. Calls Cashfree API to create an order
  ///   2. Updates `orders.cashfree_order_id` and `orders.payment_session_id`
  ///   3. Returns `{ cf_order_id, payment_session_id }`
  Future<CashfreeSessionData> createCashfreeSession({
    required String appOrderId,
    required double amount,
    required String customerPhone,
    String? customerEmail,
    String? customerName,
    String? customerId,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase.functions.invoke(
      kCreateCashfreeOrderFunction,
      body: {
        'app_order_id': appOrderId,
        'amount': amount,
        'customer_id': customerId ?? 'guest',
        'customer_phone': customerPhone,
        'customer_email': customerEmail ?? 'customer@preorder.app',
        'customer_name': customerName ?? 'Student',
      },
    );

    if (response.status != 200) {
      throw Exception(
        'Failed to create Cashfree session (HTTP ${response.status}): ${response.data}',
      );
    }

    final data = response.data as Map<String, dynamic>;

    final cfOrderId = data['cf_order_id']?.toString();
    final paymentSessionId = data['payment_session_id']?.toString();

    if (cfOrderId == null || paymentSessionId == null) {
      throw Exception(
        'Invalid response from payment server: $data',
      );
    }

    return CashfreeSessionData(
      appOrderId: appOrderId,
      cfOrderId: cfOrderId,
      paymentSessionId: paymentSessionId,
    );
  }

  /// Calls the `verify-cashfree-payment` Supabase Edge Function.
  ///
  /// Returns `true` if payment is confirmed as PAID.
  Future<bool> verifyCashfreePayment({
    required String appOrderId,
    required String cfOrderId,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase.functions.invoke(
      kVerifyCashfreePaymentFunction,
      body: {
        'app_order_id': appOrderId,
        'cf_order_id': cfOrderId,
      },
    );

    if (response.status != 200) {
      throw Exception(
        'Payment verification failed (HTTP ${response.status}): ${response.data}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    return (data['success'] as bool?) ?? false;
  }
}
