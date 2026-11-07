import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';

final paymentControllerProvider = Provider<PaymentController>((ref) {
  return PaymentController(ref);
});

/// Data returned by [PaymentController.createRazorpayOrder] after the
/// Supabase edge function creates the order on Razorpay's server.
class RazorpaySessionData {
  final String appOrderId;       // Our own UUID from `orders` table
  final String razorpayOrderId;  // Razorpay's order_id (e.g. order_XXXX)
  final double amount;           // Amount in INR (for display)
  final String customerPhone;
  final String? customerEmail;
  final String? customerName;

  const RazorpaySessionData({
    required this.appOrderId,
    required this.razorpayOrderId,
    required this.amount,
    required this.customerPhone,
    this.customerEmail,
    this.customerName,
  });
}

class PaymentController {
  final Ref ref;

  PaymentController(this.ref);

  /// Calls the `create-razorpay-order` Supabase Edge Function.
  ///
  /// The edge function:
  ///   1. Calls Razorpay API to create an order
  ///   2. Updates `orders.razorpay_order_id`
  ///   3. Returns `{ razorpay_order_id }`
  Future<RazorpaySessionData> createRazorpayOrder({
    required String appOrderId,
    required double amount,
    required String customerPhone,
    String? customerEmail,
    String? customerName,
    String? customerId,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase.functions.invoke(
      kCreateRazorpayOrderFunction,
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
        'Failed to create Razorpay order (HTTP ${response.status}): ${response.data}',
      );
    }

    final data = response.data as Map<String, dynamic>;

    final razorpayOrderId = data['razorpay_order_id']?.toString();

    if (razorpayOrderId == null) {
      throw Exception(
        'Invalid response from payment server: $data',
      );
    }

    return RazorpaySessionData(
      appOrderId: appOrderId,
      razorpayOrderId: razorpayOrderId,
      amount: amount,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerName: customerName,
    );
  }

  /// Calls the `verify-razorpay-payment` Supabase Edge Function.
  ///
  /// Verifies payment using Razorpay signature or direct server API verification.
  /// Returns `true` if payment is confirmed as PAID.
  Future<bool> verifyRazorpayPayment({
    required String appOrderId,
    required String razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    final payload = <String, dynamic>{
      'app_order_id': appOrderId,
      'razorpay_order_id': razorpayOrderId,
    };
    if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty) {
      payload['razorpay_payment_id'] = razorpayPaymentId;
    }
    if (razorpaySignature != null && razorpaySignature.isNotEmpty) {
      payload['razorpay_signature'] = razorpaySignature;
    }

    final response = await supabase.functions.invoke(
      kVerifyRazorpayPaymentFunction,
      body: payload,
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
