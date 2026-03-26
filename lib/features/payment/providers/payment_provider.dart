import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';

final paymentControllerProvider = Provider<PaymentController>((ref) {
  return PaymentController(ref);
});

class CashfreeOrderInit {
  final String orderId;
  final String paymentLink;

  const CashfreeOrderInit({
    required this.orderId,
    required this.paymentLink,
  });
}

class PaymentController {
  final Ref ref;

  PaymentController(this.ref);

  Future<CashfreeOrderInit> createCashfreeOrder({
    required double amount,
    required int itemCount,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase.functions.invoke(
      kCreateCashfreeOrderFunction,
      body: {
        // TODO: fill these request fields with whatever your Edge Function expects.
        'amount': amount,
        'item_count': itemCount,
      },
    );

    final data = response.data as Map<String, dynamic>;

    // TODO: map these keys to your Edge Function response schema.
    final orderId = data['order_id'] as String;
    final paymentLink = data['payment_link'] as String;

    return CashfreeOrderInit(orderId: orderId, paymentLink: paymentLink);
  }

  Future<bool> verifyCashfreePayment({
    required String orderId,
    required Map<String, String> redirectQueryParams,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    final response = await supabase.functions.invoke(
      kVerifyCashfreePaymentFunction,
      body: {
        'order_id': orderId,
        // TODO: send only the params your Edge Function expects.
        ...redirectQueryParams,
      },
    );

    final data = response.data as Map<String, dynamic>;

    // TODO: map to your verify function response schema.
    return (data['success'] as bool?) ?? (data['verified'] as bool? ?? false);
  }
}

