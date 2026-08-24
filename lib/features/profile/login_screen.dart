import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/profile_provider.dart';

/// Shown when the user taps "Sign In" on the Live Promo dialog or navigates
/// to /login directly.
///
/// [onSuccess] is called after a successful login so callers can continue
/// whatever action was pending (e.g. proceed to Toss).
class LoginScreen extends ConsumerStatefulWidget {
  /// If non-null, called after successful auth instead of `context.pop()`.
  final VoidCallback? onSuccess;

  const LoginScreen({super.key, this.onSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ────────────────────────────────────────────────────────────────
  bool _isSignIn = true; // toggles between Sign In and Sign Up tabs
  bool _isVerifyingOTP = false; // true when showing OTP input after signup
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────
  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _isVerifyingOTP = false;
      _error = null;
    });
    _slideCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final notifier = ref.read(profileProvider.notifier);
    String? err;

    if (_isVerifyingOTP) {
      err = await notifier.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: _otpCtrl.text.trim(),
      );
    } else if (_isSignIn) {
      err = await notifier.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } else {
      err = await notifier.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (err == 'EMAIL_VERIFICATION_SENT') {
      setState(() {
        _isVerifyingOTP = true;
        _error = null;
      });
      _slideCtrl.forward(from: 0);
    } else if (err != null) {
      setState(() => _error = err);
    } else {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        context.pop();
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(),
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 36),
                    if (!_isVerifyingOTP) _buildTabToggle(),
                    if (!_isVerifyingOTP) const SizedBox(height: 32),
                    if (_isVerifyingOTP) ...[
                      _buildField(
                        controller: _otpCtrl,
                        label: 'Verification Code (OTP)',
                        hint: 'Enter 6-digit code',
                        icon: Icons.password,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter the code sent to your email' : null,
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      if (!_isSignIn) ...[
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Your cricket name',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 18),
                      ],
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'you@example.com',
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildPasswordField(),
                    ],
                    const SizedBox(height: 8),
                    if (_error != null) _buildError(),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                    if (!_isVerifyingOTP) ...[
                      const SizedBox(height: 24),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildGoogleButton(),
                      const SizedBox(height: 20),
                      _buildToggleText(),
                    ] else ...[
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isVerifyingOTP = false;
                              _isSignIn = true;
                              _error = null;
                            });
                          },
                          child: Text(
                            'Back to Sign In',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cricket ball accent
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFBA0013), Color(0xFF7B000D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBA0013).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.sports_cricket, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 20),
        Text(
          _isVerifyingOTP 
              ? 'Verify Email,' 
              : _isSignIn ? 'Welcome back,' : 'Join Scorely,',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _isVerifyingOTP 
              ? 'Enter Code'
              : _isSignIn ? 'Sign in to score live' : 'Score cricket live',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (_isVerifyingOTP) ...[
          const SizedBox(height: 12),
          Text(
            'We sent a verification code to ${_emailCtrl.text.trim()}.',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildTabToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tab('Sign In', _isSignIn),
          _tab('Sign Up', !_isSignIn),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : _toggleMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFBA0013) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: active ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: Colors.white,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white30, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            errorStyle: GoogleFonts.inter(
              color: const Color(0xFFFF6B6B),
              fontSize: 11,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFBA0013), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          cursorColor: Colors.white,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white30, size: 20),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white30,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            errorStyle: GoogleFonts.inter(
              color: const Color(0xFFFF6B6B),
              fontSize: 11,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFBA0013), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: const Color(0xFFFF6B6B),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBA0013),
          disabledBackgroundColor: const Color(0xFFBA0013).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isVerifyingOTP 
                    ? 'VERIFY'
                    : _isSignIn ? 'SIGN IN' : 'CREATE ACCOUNT',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleText() {
    return Center(
      child: GestureDetector(
        onTap: _toggleMode,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 13),
            children: [
              TextSpan(
                text: _isSignIn
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: const TextStyle(color: Colors.white54),
              ),
              TextSpan(
                text: _isSignIn ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                
                // Call the auth service for Google login
                final notifier = ref.read(profileProvider.notifier);
                final err = await notifier.signInWithGoogle();
                
                if (!mounted) return;
                setState(() => _loading = false);
                
                if (err != null) {
                  setState(() => _error = err);
                } else {
                  if (widget.onSuccess != null) {
                    widget.onSuccess!();
                  } else {
                    context.pop();
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
          height: 24,
          width: 24,
        ),
        label: Text(
          'Continue with Google',
          style: GoogleFonts.inter(
            color: const Color(0xFF191C1E),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
