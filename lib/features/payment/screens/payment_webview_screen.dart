import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../cart/providers/cart_controller.dart';
import '../../payment/providers/payment_provider.dart';

class PaymentWebviewScreen extends ConsumerStatefulWidget {
  const PaymentWebviewScreen({super.key});

  @override
  ConsumerState<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  late final WebViewController _controller;

  bool _loadingPayment = true;
  bool _verificationTriggered = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            return _handleNavigationRequest(request.url);
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPaymentFlow();
    });
  }

  Future<void> _startPaymentFlow() async {
    final cartAsync = ref.watch(cartControllerProvider);
    final cart = cartAsync.asData?.value;
    if (cart == null || cart.lines.isEmpty) {
      if (!mounted) return;
      setState(() => _loadingPayment = false);
      return;
    }

    // The Edge Function may create an order in your DB and return the cashfree payment link.
    final paymentController = ref.read(paymentControllerProvider);
    final init = await paymentController.createCashfreeOrder(
      amount: cart.totalAmount,
      itemCount: cart.itemCount,
    );

    if (!mounted) return;
    _orderId = init.orderId;
    setState(() => _loadingPayment = false);
    await _controller.loadRequest(Uri.parse(init.paymentLink));
  }

  Future<NavigationDecision> _handleNavigationRequest(String url) async {
    // TODO: replace this marker with the exact redirect/callback URL pattern
    // your Edge Function/Cashfree is configured to call.
    const redirectMarker = 'TODO_REDIRECT_MARKER';

    if (_orderId == null || _verificationTriggered) {
      return NavigationDecision.navigate;
    }

    if (!url.contains(redirectMarker)) {
      return NavigationDecision.navigate;
    }

    _verificationTriggered = true;

    try {
      final uri = Uri.parse(url);
      final query = uri.queryParameters;

      final paymentController = ref.read(paymentControllerProvider);
      final ok = await paymentController.verifyCashfreePayment(
        orderId: _orderId!,
        redirectQueryParams: query,
      );

      if (ok) {
        ref.read(cartControllerProvider.notifier).clear();
        if (!mounted) return NavigationDecision.prevent;
        context.go('/orders');
        return NavigationDecision.prevent;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed (TODO).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed (error).')),
        );
      }
    }

    return NavigationDecision.prevent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay with Cashfree')),
      body: _loadingPayment
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _controller),
    );
  }
}

