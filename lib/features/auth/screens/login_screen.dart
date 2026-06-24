import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    final session = AuthScope.of(context, listen: false);
    final succeeded = await session.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.newsfeed, (route) => false);
      return;
    }
    showAppMessage(
      context,
      session.errorMessage ?? 'Could not log in. Please try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                36,
                horizontalPadding,
                28,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back', style: serifTitle(40)),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue your origami journey',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 42),
                    const Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('emailField'),
                      controller: _emailController,
                      enabled: !session.isBusy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'your@email.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) return 'Email is not valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Password',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('passwordField'),
                      controller: _passwordController,
                      enabled: !session.isBusy,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!session.isBusy) _login();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            showAppMessage(context, 'Password reset link sent'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: session.isBusy ? 'Logging in...' : 'Log In',
                      onPressed: session.isBusy ? null : _login,
                    ),
                    const SizedBox(height: 28),
                    const _AuthDivider(),
                    const SizedBox(height: 22),
                    _SocialLoginButtons(
                      busy: session.isBusy,
                      style: _socialStyle(),
                    ),
                    const SizedBox(height: 26),
                    Column(
                      children: [
                        const SizedBox(
                          width: double.infinity,
                          child: Text(
                            "Don't have an account?",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        ),
                        TextButton(
                          onPressed: session.isBusy
                              ? null
                              : () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.signup,
                                ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _socialStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      minimumSize: const Size(0, 50),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    const label = Text(
      'Or continue with',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.mutedText, fontSize: 13),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 200) return label;
        return const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: label,
            ),
            Expanded(child: Divider()),
          ],
        );
      },
    );
  }
}

class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons({required this.busy, required this.style});

  final bool busy;
  final ButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final google = OutlinedButton.icon(
      onPressed: busy
          ? null
          : () => showAppMessage(context, 'Google login is not configured yet'),
      icon: const Icon(Icons.g_mobiledata, size: 25),
      label: const Text('Google'),
      style: style,
    );
    final apple = OutlinedButton.icon(
      onPressed: busy
          ? null
          : () => showAppMessage(context, 'Apple login is not configured yet'),
      icon: const Icon(Icons.apple),
      label: const Text('Apple'),
      style: style,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [google, const SizedBox(height: 12), apple],
          );
        }
        return Row(
          children: [
            Expanded(child: google),
            const SizedBox(width: 12),
            Expanded(child: apple),
          ],
        );
      },
    );
  }
}
