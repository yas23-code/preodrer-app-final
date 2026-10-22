import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../cart/providers/cart_controller.dart';
import '../../payment/providers/payment_provider.dart';

/// Screen that opens the Cashfree native payment sheet.
///
/// Expects [GoRouterState.extra] to be a [CashfreeSessionData] instance,
/// passed by CartScreen after calling [CartController.initiatePayment()].
class PaymentWebviewScreen extends ConsumerStatefulWidget {
  const PaymentWebviewScreen({super.key});

  @override
  ConsumerState<PaymentWebviewScreen> createState() =>
      _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  // Singleton gateway service — use factory constructor
  final CFPaymentGatewayService _cfService = CFPaymentGatewayService();

  bool _isLoading = true;
  bool _paymentDone = false;
  bool _paymentSuccess = false;
  String? _statusMessage;

  CashfreeSessionData? _session;
  bool _sessionExtracted = false;

  @override
  void initState() {
    super.initState();
    // Register callbacks BEFORE the sheet is opened
    _cfService.setCallback(_onPaymentVerify, _onPaymentError);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionExtracted) {
      _sessionExtracted = true;
      // Extract the session data passed via GoRouter extra
      final extra = GoRouterState.of(context).extra;
      if (extra is CashfreeSessionData) {
        _session = extra;
        WidgetsBinding.instance.addPostFrameCallback((_) => _openPaymentSheet());
      } else {
        // Fallback: no session data, go back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment session not found. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
            context.go('/cart');
          }
        });
      }
    }
  }

  Future<void> _openPaymentSheet() async {
    final session = _session;
    if (session == null) return;

    try {
      // Build Cashfree session — use cfOrderId as the orderId for the SDK
      final cfSession = CFSessionBuilder()
          .setEnvironment(CFEnvironment.PRODUCTION)
          .setOrderId(session.cfOrderId)
          .setPaymentSessionId(session.paymentSessionId)
          .build();

      // Build web checkout payment object
      final cfWebCheckoutPayment = CFWebCheckoutPaymentBuilder()
          .setSession(cfSession)
          .build();

      // Open native payment sheet
      _cfService.doPayment(cfWebCheckoutPayment);
    } catch (e) {
      debugPrint('[PaymentScreen] Error opening payment sheet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _paymentDone = true;
          _paymentSuccess = false;
          _statusMessage = 'Failed to open payment. Please try again.\n$e';
        });
      }
    }
  }

  // ── Cashfree SDK callback: payment initiated — verify server-side ─────
  void _onPaymentVerify(String orderId) async {
    debugPrint('[PaymentScreen] _onPaymentVerify called with orderId=$orderId');
    if (!mounted) return;
    setState(() => _isLoading = true);

    final session = _session;
    if (session == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _paymentDone = true;
          _paymentSuccess = false;
          _statusMessage = 'Session lost. Please check your orders.';
        });
      }
      return;
    }

    try {
      final paymentController = ref.read(paymentControllerProvider);
      final ok = await paymentController.verifyCashfreePayment(
        appOrderId: session.appOrderId,
        cfOrderId: session.cfOrderId,
      );

      if (ok) {
        // Clear cart + refresh orders list
        await ref.read(cartControllerProvider.notifier).onPaymentSuccess();

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _paymentDone = true;
          _paymentSuccess = true;
          _statusMessage = '🎉 Payment Successful!';
        });

        // Redirect to orders after brief success display
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/orders');
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _paymentDone = true;
          _paymentSuccess = false;
          _statusMessage =
              'Payment could not be verified. Please check your orders or contact support.';
        });
      }
    } catch (e) {
      debugPrint('[PaymentScreen] Verification error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _paymentDone = true;
          _paymentSuccess = false;
          _statusMessage = 'Verification failed: $e';
        });
      }
    }
  }

  // ── Cashfree SDK callback: payment error/cancelled ────────────────────
  void _onPaymentError(CFErrorResponse error, String orderId) {
    debugPrint(
        '[PaymentScreen] _onPaymentError: ${error.getMessage()}, orderId=$orderId');
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _paymentDone = true;
      _paymentSuccess = false;
      _statusMessage = error.getMessage() ?? 'Payment was cancelled or failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFFFF9EC);
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _paymentDone
              ? _buildResult(isDark, textPrimary, textSecondary)
              : _buildLoading(isDark),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isLoading && _session != null
                ? 'Verifying Payment...'
                : 'Opening Payment...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete payment in the Cashfree screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      key: const ValueKey('result'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (_paymentSuccess ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _paymentSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                size: 60,
                color: _paymentSuccess ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _paymentSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // Action button (only shown on failure)
            if (!_paymentSuccess)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go('/cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Cart',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            if (_paymentSuccess)
              Text(
                'Redirecting to your orders...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
