import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../cart/providers/cart_controller.dart';
import '../../payment/providers/payment_provider.dart';

/// Screen that opens the Razorpay payment sheet.
///
/// Expects [GoRouterState.extra] to be a [RazorpaySessionData] instance,
/// passed by CartScreen after calling [CartController.initiatePayment()].
class PaymentWebviewScreen extends ConsumerStatefulWidget {
  const PaymentWebviewScreen({super.key});

  @override
  ConsumerState<PaymentWebviewScreen> createState() =>
      _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  late Razorpay _razorpay;

  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _paymentDone = false;
  bool _paymentSuccess = false;
  String? _statusMessage;

  RazorpaySessionData? _session;
  bool _sessionExtracted = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionExtracted) {
      _sessionExtracted = true;
      // Extract the session data passed via GoRouter extra
      final extra = GoRouterState.of(context).extra;
      if (extra is RazorpaySessionData) {
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

  void _openPaymentSheet() {
    final session = _session;
    if (session == null) return;

    try {
      final razorpayKeyId = dotenv.env[kRazorpayKeyIdEnvKey] ?? '';
      if (razorpayKeyId.isEmpty) {
        throw Exception('Razorpay Key ID not configured in .env');
      }

      // Amount must be in paise (INR × 100) for Razorpay
      final amountInPaise = (session.amount * 100).toInt();

      final options = {
        'key': razorpayKeyId,
        'amount': amountInPaise,
        'order_id': session.razorpayOrderId,
        'name': 'Preorder App',
        'description': 'Order #${session.appOrderId.substring(0, 8)}',
        'prefill': {
          'contact': session.customerPhone,
          'email': session.customerEmail ?? 'customer@preorder.app',
          'name': session.customerName ?? 'Student',
        },
        'theme': {
          'color': '#E53935', // AppColors.accent
        },
      };

      _razorpay.open(options);
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

  // ── Helper to verify order status with backend / Razorpay API ────────
  Future<bool> _verifyWithBackend({
    String? paymentId,
    String? signature,
  }) async {
    final session = _session;
    if (session == null) return false;

    try {
      final paymentController = ref.read(paymentControllerProvider);
      final ok = await paymentController.verifyRazorpayPayment(
        appOrderId: session.appOrderId,
        razorpayOrderId: session.razorpayOrderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (ok) {
        // Clear cart + refresh orders list
        await ref.read(cartControllerProvider.notifier).onPaymentSuccess();

        if (!mounted) return true;
        setState(() {
          _isLoading = false;
          _isCheckingStatus = false;
          _paymentDone = true;
          _paymentSuccess = true;
          _statusMessage = '🎉 Payment Successful!';
        });

        // Redirect to orders after brief success display
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/orders');
        return true;
      }
    } catch (e) {
      debugPrint('[PaymentScreen] Verification error: $e');
    }
    return false;
  }

  // ── Razorpay callback: payment successful — verify server-side ────────
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint(
        '[PaymentScreen] _onPaymentSuccess: paymentId=${response.paymentId}, orderId=${response.orderId}');
    if (!mounted) return;
    setState(() => _isLoading = true);

    final ok = await _verifyWithBackend(
      paymentId: response.paymentId,
      signature: response.signature,
    );

    if (!ok && mounted) {
      setState(() {
        _isLoading = false;
        _paymentDone = true;
        _paymentSuccess = false;
        _statusMessage =
            'Payment could not be verified yet. If money was deducted, click "Check Payment Status" below.';
      });
    }
  }

  // ── Razorpay callback: payment error / timeout / cancellation ─────────
  void _onPaymentError(PaymentFailureResponse response) async {
    debugPrint(
        '[PaymentScreen] _onPaymentError: code=${response.code}, message=${response.message}');
    if (!mounted) return;

    // CRITICAL: Do NOT immediately mark as failed!
    // In UPI apps (GPay, PhonePe, Paytm), money is often deducted at the bank
    // before the callback returns to Flutter, causing SDK to trigger _onPaymentError.
    // Query our backend to check if Razorpay captured the payment!
    setState(() {
      _isLoading = true;
      _statusMessage = 'Confirming payment with your bank...';
    });

    // Check 1: Immediate check with server
    final ok1 = await _verifyWithBackend();
    if (ok1) return;

    // Check 2: Wait 2.5 seconds and retry (UPI webhook/settlement delay)
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final ok2 = await _verifyWithBackend();
    if (ok2) return;

    // If still not verified, show friendly screen with retry option
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _paymentDone = true;
      _paymentSuccess = false;
      _statusMessage =
          'Payment not received. If money was debited from your bank account, click "Check Payment Status" below to verify.';
    });
  }

  // ── Manual Status Check Button ────────────────────────────────────────
  Future<void> _handleManualCheck() async {
    setState(() {
      _isCheckingStatus = true;
      _statusMessage = 'Checking with payment gateway...';
    });

    final ok = await _verifyWithBackend();
    if (!ok && mounted) {
      setState(() {
        _isCheckingStatus = false;
        _statusMessage =
            'Payment is not yet confirmed by the bank. If money was debited, it will either settle or be automatically refunded within 24-48 hours.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment not found yet. Please check again in a minute.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ── Razorpay callback: external wallet selected ───────────────────────
  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PaymentScreen] External wallet selected: ${response.walletName}');
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
                ? (_statusMessage ?? 'Verifying Payment...')
                : 'Opening Payment...',
            textAlign: TextAlign.center,
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
            'Please complete payment in the Razorpay screen',
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
              _paymentSuccess ? 'Payment Successful!' : 'Payment Pending / Failed',
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

            // Check Payment Status Button (for when money was deducted)
            if (!_paymentSuccess) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingStatus ? null : _handleManualCheck,
                  icon: _isCheckingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    _isCheckingStatus
                        ? 'Checking...'
                        : 'Check Payment Status',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.go('/cart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Cart',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

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
