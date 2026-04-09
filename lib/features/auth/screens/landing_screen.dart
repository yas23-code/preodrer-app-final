import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNavBar(context),
              const Divider(height: 1, color: Color(0xFFEDE5D5)),
              _buildHeroSection(context),
              _buildFAQSection(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. NAVBAR — responsive, uses LayoutBuilder to adapt
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildNavBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 20,
            vertical: 10,
          ),
          color: AppColors.bgCream,
          child: Row(
            children: [
              // Logo
              Container(
                width: isNarrow ? 32 : 38,
                height: isNarrow ? 32 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.buttonGradient,
                ),
                child: Icon(Icons.fastfood_rounded,
                    color: Colors.white, size: isNarrow ? 16 : 20),
              ),
              const SizedBox(width: 6),
              // Brand name
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'pre',
                      style: TextStyle(
                        fontSize: isNarrow ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextSpan(
                      text: 'order',
                      style: TextStyle(
                        fontSize: isNarrow ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              // Login link
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 4 : 8),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: isNarrow ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              // Crown icon — hidden on very narrow
              if (!isNarrow) ...[
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.primary, size: 18),
                ),
              ],
              SizedBox(width: isNarrow ? 6 : 8),
              // Get Started button
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 16,
                    vertical: isNarrow ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    isNarrow ? 'Start' : 'Get Started',
                    style: TextStyle(
                      fontSize: isNarrow ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. HERO SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: AppColors.bgCream),
          child: Stack(
            children: [
              // Animated blobs
              Positioned(
                top: 30 + (_blobController.value * 20),
                left: -40,
                child: _buildBlob(140, const Color(0x20F5A623)),
              ),
              Positioned(
                top: 80 - (_blobController.value * 15),
                right: -30,
                child: _buildBlob(120, const Color(0x18FFD580)),
              ),
              Positioned(
                bottom: 100 + (_blobController.value * 10),
                left: 30,
                child: _buildBlob(90, const Color(0x15E8A020)),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // Pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child:
                                const Text('✨', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Campus food, simplified',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Big headline
                    const Text(
                      'Skip the Queue,',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE8A020), Color(0xFFD4881A)],
                      ).createShader(bounds),
                      child: const Text(
                        'Grab Your Food',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Hero image card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3D6), Color(0xFFFFEDC2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE8A020).withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circles
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE8A020)
                                      .withOpacity(0.08),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -10,
                              left: -10,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFD0021B)
                                      .withOpacity(0.06),
                                ),
                              ),
                            ),
                            // Center icon
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE8A020)
                                            .withOpacity(0.2),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 56,
                                    color: Color(0xFFD0021B),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '🍽️ Order ahead, skip the wait!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Floating chips
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _floatingChip('Ugh... not again!', '😩'),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: _floatingChip('Quick & easy', '⚡'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Order from your favorite campus canteens, pay ahead, and pick up when ready.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // CTA button
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF5A623)
                                  .withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Feature pills
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeaturePill(
                            icon: Icons.flash_on_rounded,
                            label: 'Order in seconds'),
                        _FeaturePill(
                            icon: Icons.notifications_active_rounded,
                            label: 'Live updates'),
                        _FeaturePill(
                            icon: Icons.payments_rounded,
                            label: 'Easy payments'),
                      ],
                    ),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _floatingChip(String text, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. FAQ SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFAQSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Got questions? We\'ve got answers.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _FAQCard(
            question: 'How do I place an order?',
            answer:
                'Simply browse the menu from your campus canteen, add items to your cart, and proceed to checkout. Pay online and pick up when your order is ready!',
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 12),
          const _FAQCard(
            question: 'What payment methods are accepted?',
            answer:
                'We accept UPI, credit/debit cards, net banking, and popular wallets like Paytm, PhonePe, and Google Pay for seamless transactions.',
            icon: Icons.payment_outlined,
          ),
          const SizedBox(height: 12),
          const _FAQCard(
            question: 'How do I know when my order is ready?',
            answer:
                'You\'ll receive a push notification as soon as your order is prepared and ready for pickup. You can also track your order status in real-time.',
            icon: Icons.notifications_outlined,
          ),
          const SizedBox(height: 12),
          const _FAQCard(
            question: 'Can I cancel or modify my order?',
            answer:
                'You can cancel or modify your order within a few minutes of placing it, before the canteen starts preparing it. Check the order details page.',
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 12),
          const _FAQCard(
            question: 'What if I face any issues with my order?',
            answer:
                'Reach out to us through in-app support or email us. We\'re committed to resolving any issues quickly and ensuring a great experience.',
            icon: Icons.support_agent_outlined,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. FOOTER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1410),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main footer content — wraps on narrow screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Stack vertically on narrow
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _footerBranding(),
                    const SizedBox(height: 24),
                    _footerPolicies(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _footerBranding()),
                  Expanded(flex: 2, child: _footerPolicies()),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${DateTime.now().year} preorder.food — All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(children: [
            TextSpan(
              text: 'pre',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            TextSpan(
              text: 'order',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            TextSpan(
              text: '.food',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white54),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
          'Skip the queue, grab your food.\nThe easiest way to order from\nyour campus canteens.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _footerPolicies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Policies',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _footerLink('Privacy Policy'),
        const SizedBox(height: 8),
        _footerLink('Terms & Conditions'),
        const SizedBox(height: 8),
        _footerLink('Refund Policy'),
        const SizedBox(height: 8),
        _footerLink('Contact / Support'),
      ],
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withOpacity(0.5),
        height: 1.3,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FAQ Card — expandable accordion
// ═══════════════════════════════════════════════════════════════════════
class _FAQCard extends StatefulWidget {
  final String question;
  final String answer;
  final IconData icon;

  const _FAQCard({
    required this.question,
    required this.answer,
    required this.icon,
  });

  @override
  State<_FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _iconController.forward() : _iconController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _expanded ? const Color(0xFFFFF8E7) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppColors.primary.withOpacity(0.3)
                : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? AppColors.primary.withOpacity(0.12)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: _expanded ? AppColors.primary : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _expanded ? AppColors.textDark : Colors.grey[700],
                    ),
                  ),
                ),
                RotationTransition(
                  turns:
                      Tween(begin: 0.0, end: 0.5).animate(_iconController),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _expanded ? AppColors.primary : Colors.grey[400],
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14, left: 48),
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.55,
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Feature Pill
// ═══════════════════════════════════════════════════════════════════════
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.gradientEnd),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}