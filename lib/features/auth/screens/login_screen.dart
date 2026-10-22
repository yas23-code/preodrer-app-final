import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../../../core/supabase_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedTab = 0; // 0=Login, 1=SignUp, 2=ShopOwner

  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Sign Up controllers
  final _signUpNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();


  // Shop Owner controllers
  final _shopNameCtrl = TextEditingController();
  final _shopCanteenNameCtrl = TextEditingController();
  final _shopEmailCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _shopLocationCtrl = TextEditingController();
  final _shopPasswordCtrl = TextEditingController();

  bool _obscureLoginPw = true;
  bool _obscureSignUpPw = true;
  bool _obscureShopPw = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _shopNameCtrl.dispose();
    _shopCanteenNameCtrl.dispose();
    _shopEmailCtrl.dispose();
    _shopPhoneCtrl.dispose();
    _shopLocationCtrl.dispose();
    _shopPasswordCtrl.dispose();
    super.dispose();
  }

  // ─── Auth handlers ────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }
    await _runAuth(() async {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: email, password: password);
      // Force providers to re-fetch for the newly logged-in user
      ref.invalidate(roleProvider);
      ref.invalidate(vendorStatusProvider);
      ref.invalidate(myRegistrationProvider);
    });
  }

  Future<void> _handleSignUp() async {
    final name = _signUpNameCtrl.text.trim();
    final email = _signUpEmailCtrl.text.trim();
    final password = _signUpPasswordCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    await _runAuth(() async {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
            fullName: name,
            role: 'student',
          );
    });
  }

  Future<void> _handleShopOwnerSignUp() async {
    final name = _shopNameCtrl.text.trim();
    final canteenName = _shopCanteenNameCtrl.text.trim();
    final email = _shopEmailCtrl.text.trim();
    final phone = _shopPhoneCtrl.text.trim();
    final location = _shopLocationCtrl.text.trim();
    final password = _shopPasswordCtrl.text.trim();

    if (name.isEmpty || canteenName.isEmpty || email.isEmpty || phone.isEmpty || location.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    await _runAuth(() async {
      // Register as 'vendor' role so roleProvider identifies them correctly.
      // They remain gated by vendorStatus='pending' until admin approval.
      final user = await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
            fullName: name,
            role: 'vendor',
          );

      // Also insert into user_roles so roleProvider picks up 'vendor'
      final supabase = ref.read(supabaseClientProvider);
      try {
        await supabase.from('user_roles').upsert({
          'user_id': user.id,
          'role': 'vendor',
        });
      } catch (_) {}

      await supabase.from('canteen_registrations').insert({
        'user_id': user.id,
        'owner_name': name,
        'canteen_name': canteenName,
        'email': email,
        'phone': phone,
        'location': location,
        'status': 'pending',
      });

      // Force providers to re-fetch with the new registration data
      ref.invalidate(vendorStatusProvider);
      ref.invalidate(myRegistrationProvider);
      ref.invalidate(roleProvider);
    });
  }

  Future<void> _handleGoogleSignIn() async {
    await _runAuth(() async {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      // Force providers to re-fetch for the newly logged-in user
      ref.invalidate(roleProvider);
      ref.invalidate(vendorStatusProvider);
      ref.invalidate(myRegistrationProvider);
    });
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) context.go('/home');
    } on AuthCancelledException {
      // User deliberately cancelled — show a mild, non-alarming message
      _showCancelledHint();
    } catch (e) {
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    developer.log('Auth error: $msg', name: 'LoginScreen');
    if (msg.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('User already registered')) {
      return 'An account with this email already exists. Try logging in.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    // Show the actual error for debugging instead of generic message
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    // Strip exception class prefixes for cleaner display
    return msg
        .replaceAll('StateError: ', '')
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '');
  }

  void _showCancelledHint() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sign-in cancelled.'),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDA291C), // mcd-red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Background Cream
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNavBar(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Welcome to preorder.food',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Your campus food companion',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTabSelector(),
                      const SizedBox(height: 24),
                      // Tab-specific content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildTabContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedTab) {
      0 => _buildLoginContent(),
      1 => _buildSignUpContent(),
      2 => _buildShopOwnerContent(),
      _ => _buildLoginContent(),
    };
  }

  // ─── NAV BAR ──────────────────────────────────────────────────────

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'pre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextSpan(
                      text: 'order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDA291C), // mcd-red
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB SELECTOR ─────────────────────────────────────────────────

  Widget _buildTabSelector() {
    final tabs = ['Login', 'Sign Up', 'Shop Owner'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slight gray to match web tabs bg
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6)
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (i == 2) ...[
                      Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: selected ? Colors.black : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        tabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.black : Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── LOGIN TAB ────────────────────────────────────────────────────

  Widget _buildLoginContent() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AuthLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _loginEmailCtrl,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Password'),
        const SizedBox(height: 8),
        _AuthPasswordField(
          controller: _loginPasswordCtrl,
          obscure: _obscureLoginPw,
          onToggle: () => setState(() => _obscureLoginPw = !_obscureLoginPw),
        ),
        const SizedBox(height: 24),
        _GradientActionButton(
          label: 'Login',
          isLoading: _isLoading,
          onTap: _handleLogin,
        ),
        const SizedBox(height: 16),
        _buildOrDivider(),
        const SizedBox(height: 16),
        _GoogleButton(onTap: _handleGoogleSignIn),
      ],
    );
  }

  // ─── SIGN UP TAB ──────────────────────────────────────────────────

  Widget _buildSignUpContent() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AuthLabel('Full Name'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _signUpNameCtrl,
          hint: 'John Doe',
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _signUpEmailCtrl,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Password'),
        const SizedBox(height: 8),
        _AuthPasswordField(
          controller: _signUpPasswordCtrl,
          obscure: _obscureSignUpPw,
          onToggle: () =>
              setState(() => _obscureSignUpPw = !_obscureSignUpPw),
        ),
        const SizedBox(height: 24),
        _GradientActionButton(
          label: 'Create Account',
          isLoading: _isLoading,
          onTap: _handleSignUp,
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Want to sell food? ',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 2),
                child: const Text(
                  'Register as Shop Owner',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDA291C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SHOP OWNER TAB ───────────────────────────────────────────────

  Widget _buildShopOwnerContent() {
    return Column(
      key: const ValueKey('shopowner'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match the info box from Auth.tsx
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // bgCream / accent/10
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFC300).withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on_rounded, color: Color(0xFFDA291C), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Register Your Shop',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Get discovered by nearby customers. Add your shop location and start receiving orders!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

         const _AuthLabel('Your Name'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopNameCtrl,
          hint: 'Shop Owner Name',
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Shop/Canteen Name'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopCanteenNameCtrl,
          hint: 'e.g. Campus Corner Canteen',
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopEmailCtrl,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Phone Number'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopPhoneCtrl,
          hint: 'e.g. +91 9876543210',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Location'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopLocationCtrl,
          hint: 'e.g. Block C, Ground Floor',
        ),
        const SizedBox(height: 16),
        const _AuthLabel('Password'),
        const SizedBox(height: 8),
        _AuthPasswordField(
          controller: _shopPasswordCtrl,
          obscure: _obscureShopPw,
          onToggle: () => setState(() => _obscureShopPw = !_obscureShopPw),
        ),
        const SizedBox(height: 24),
        _GradientActionButton(
          label: 'Register & Add Your Shop',
          isLoading: _isLoading,
          onTap: _handleShopOwnerSignUp,
          showArrow: true,
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: const Text(
                  'Login here',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDA291C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── OR Divider ───────────────────────────────────────────────────

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[200])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey[200])),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Reusable private widgets
// ═══════════════════════════════════════════════════════════════════════

class _AuthLabel extends StatelessWidget {
  final String text;
  const _AuthLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      enableSuggestions: autocorrect,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // subtle cool grayish white
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC300), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _AuthPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey[400],
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC300), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final bool showArrow;

  const _GradientActionButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
             colors: [Color(0xFFDA291C), Color(0xFFFFC300)], // red to yellow
             begin: Alignment.centerLeft,
             end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDA291C).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (showArrow) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ]
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.02),
               blurRadius: 4,
               offset: const Offset(0, 2),
             )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
