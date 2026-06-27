import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/card_container.dart';
import '../widgets/animations.dart';
import '../widgets/animated_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (name.length < 2) {
      setState(
          () => _errorMessage = 'Name must be at least 2 characters');
      return;
    }

    if (name.length > 50) {
      setState(
          () => _errorMessage = 'Name must be 50 characters or less');
      return;
    }

    if (!RegExp(r"^[a-zA-Z][a-zA-Z\s.'-]*$").hasMatch(name)) {
      setState(() => _errorMessage =
          "Name can only include letters, spaces, . ' and -");
      return;
    }

    if (email.length > 254) {
      setState(() => _errorMessage = 'Email is too long');
      return;
    }

    if (email.contains(' ') ||
        !RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            .hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    if (password.length < 8) {
      setState(() =>
          _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    if (password.length > 64) {
      setState(() =>
          _errorMessage = 'Password must be 64 characters or less');
      return;
    }

    if (password.contains(' ')) {
      setState(
          () => _errorMessage = 'Password cannot contain spaces');
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must include an uppercase letter');
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must include a lowercase letter');
      return;
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      setState(
          () => _errorMessage = 'Password must include a number');
      return;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]~`+=;]')
        .hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must include a special character');
      return;
    }

    if (password.toLowerCase() == email.toLowerCase()) {
      setState(() => _errorMessage =
          'Password cannot be the same as your email');
      return;
    }

    if (password
        .toLowerCase()
        .contains(name.toLowerCase().split(' ').first)) {
      setState(() =>
          _errorMessage = 'Password should not contain your name');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (!_agreedToTerms) {
      setState(() =>
          _errorMessage = 'Please agree to terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage =
                e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF6A1B4D),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF5F7),
              Color(0xFFFFF0F3),
              Color(0xFFF6F0FF)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEA4C89).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Header — staggered entrance
                        FadeInSlide(
                          duration:
                              const Duration(milliseconds: 450),
                          delay: const Duration(milliseconds: 80),
                          child: Column(
                            children: [
                              // Logo mark
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFEA4C89),
                                      Color(0xFF6C5CE7)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Join Flowra',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4A154B),
                                  letterSpacing: -0.8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create your account and take control of your health',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Card — staggered
                        FadeInSlide(
                          duration:
                              const Duration(milliseconds: 450),
                          delay:
                              const Duration(milliseconds: 180),
                          child: CardContainer(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // Error
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding:
                                        const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(
                                          color:
                                              Colors.red.shade200),
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                            Icons.error_outline,
                                            color:
                                                Colors.red.shade700,
                                            size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Colors
                                                  .red.shade800,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                ],

                                // Full Name
                                AnimatedField(
                                  controller: _nameController,
                                  labelText: 'Full Name',
                                  hintText: 'Sarah',
                                  enabled: !_isLoading,
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded),
                                ),
                                const SizedBox(height: 16),

                                // Email
                                AnimatedField(
                                  controller: _emailController,
                                  labelText: 'Email Address',
                                  hintText: 'sarah@example.com',
                                  enabled: !_isLoading,
                                  keyboardType: TextInputType
                                      .emailAddress,
                                  prefixIcon: const Icon(
                                      Icons.email_outlined),
                                ),
                                const SizedBox(height: 16),

                                // Password
                                AnimatedField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  hintText: 'At least 8 characters',
                                  enabled: !_isLoading,
                                  obscureText: _obscurePassword,
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                      size: 20,
                                      color:
                                          const Color(0xFF718096),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password
                                AnimatedField(
                                  controller:
                                      _confirmPasswordController,
                                  labelText: 'Confirm Password',
                                  hintText:
                                      'Re-enter your password',
                                  enabled: !_isLoading,
                                  obscureText:
                                      _obscureConfirmPassword,
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                      size: 20,
                                      color:
                                          const Color(0xFF718096),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Terms
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: _isLoading
                                          ? null
                                          : (v) => setState(
                                              () => _agreedToTerms =
                                                  v ?? false),
                                      activeColor:
                                          const Color(0xFFEA4C89),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  4)),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                              color: Colors
                                                  .grey.shade700,
                                              fontSize: 12,
                                              height: 1.3),
                                          children: const [
                                            TextSpan(
                                                text:
                                                    'I agree to the '),
                                            TextSpan(
                                              text:
                                                  'Terms & Conditions',
                                              style: TextStyle(
                                                color: Color(
                                                    0xFFEA4C89),
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: Color(
                                                    0xFFEA4C89),
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                PrimaryButton(
                                  label: 'Create Account',
                                  busy: _isLoading,
                                  onPressed: _isLoading
                                      ? null
                                      : _handleRegister,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login link — staggered
                        FadeInSlide(
                          duration:
                              const Duration(milliseconds: 450),
                          delay:
                              const Duration(milliseconds: 280),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context)
                                            .pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen(),
                                          ),
                                        );
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize
                                          .shrinkWrap,
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color(0xFFEA4C89),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
