import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../providers/auth_provider.dart';

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
  int _selectedRole = 0; // 0=Student, 1=Vendor

  // Shop Owner controllers
  final _shopNameCtrl = TextEditingController();
  final _shopEmailCtrl = TextEditingController();
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
    _shopEmailCtrl.dispose();
    _shopPasswordCtrl.dispose();
    super.dispose();
  }

  // ─── Auth handlers ────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }
    await _runAuth(() async {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: email, password: password);
    });
  }

  Future<void> _handleSignUp() async {
    final name = _signUpNameCtrl.text.trim();
    final email = _signUpEmailCtrl.text.trim();
    final password = _signUpPasswordCtrl.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    final role = _selectedRole == 0 ? 'student' : 'vendor';
    await _runAuth(() async {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
            fullName: name,
            role: role,
          );
    });
  }

  Future<void> _handleShopOwnerSignUp() async {
    final name = _shopNameCtrl.text.trim();
    final email = _shopEmailCtrl.text.trim();
    final password = _shopPasswordCtrl.text;
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
            role: 'vendor',
          );
    });
  }

  Future<void> _handleGoogleSignIn() async {
    await _runAuth(() async {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
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
    if (msg.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('User already registered')) {
      return 'An account with this email already exists. Try logging in.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    // Strip exception class prefixes for cleaner display
    return msg
        .replaceAll('StateError: ', '')
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '');
  }

  /// Mild hint shown when user cancels the sign-in flow themselves.
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

  /// Red error snackbar for real failures.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.gradientEnd,
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
      backgroundColor: AppColors.bgCream,
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
                      const Text(
                        'Welcome to preorder.food',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
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
                      const SizedBox(height: 20),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.buttonGradient,
                  ),
                  child: const Icon(Icons.fastfood_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'pre',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    TextSpan(
                      text: 'order',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Login',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
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
        color: AppColors.bgCream,
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
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppColors.textDark : Colors.grey[500],
                  ),
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
        _AuthLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _loginEmailCtrl,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _AuthLabel('Password'),
        const SizedBox(height: 8),
        _AuthPasswordField(
          controller: _loginPasswordCtrl,
          obscure: _obscureLoginPw,
          onToggle: () => setState(() => _obscureLoginPw = !_obscureLoginPw),
        ),
        const SizedBox(height: 20),
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
        _AuthLabel('Full Name'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _signUpNameCtrl,
          hint: 'John Doe',
        ),
        const SizedBox(height: 16),
        _AuthLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _signUpEmailCtrl,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _AuthLabel('Password'),
        const SizedBox(height: 8),
        _AuthPasswordField(
          controller: _signUpPasswordCtrl,
          obscure: _obscureSignUpPw,
          onToggle: () =>
              setState(() => _obscureSignUpPw = !_obscureSignUpPw),
        ),
        const SizedBox(height: 20),
        _AuthLabel('I am a'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                icon: Icons.school_rounded,
                label: 'Student',
                selected: _selectedRole == 0,
                onTap: () => setState(() => _selectedRole = 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                icon: Icons.storefront_rounded,
                label: 'Vendor',
                selected: _selectedRole == 1,
                onTap: () => setState(() => _selectedRole = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _GradientActionButton(
          label: 'Create Account',
          isLoading: _isLoading,
          onTap: _handleSignUp,
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
        _AuthLabel('Shop Owner Name'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopNameCtrl,
          hint: 'Your name',
        ),
        const SizedBox(height: 16),
        _AuthLabel('Email'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _shopEmailCtrl,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _AuthLabel('Password'),
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
        color: AppColors.textDark,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        filled: true,
        fillColor: AppColors.bgCream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber[100]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber[100]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        filled: true,
        fillColor: AppColors.bgCream,
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
          borderSide: BorderSide(color: Colors.amber[100]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.amber[100]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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

  const _GradientActionButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A623).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
          color: AppColors.bgCream,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.amber[200]!, width: 1.5),
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
                    fontWeight: FontWeight.w700,
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
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3D6) : AppColors.bgCream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.amber[100]!,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.primary : Colors.grey[500],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.textDark : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}