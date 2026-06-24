import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/auth/registration.dart';
import 'package:origami/core/widgets/common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_formKey.currentState?.validate() != true) return;
    final registration = RegistrationDraft(
      displayName: _nameController.text.trim(),
      handle: _handleController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    final session = AuthScope.of(context, listen: false);
    final challenge = await session.requestRegistrationOtp(registration.email);
    if (!mounted) return;
    if (challenge == null) {
      showAppMessage(
        context,
        session.errorMessage ?? 'Could not send the verification code.',
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpVerificationScreen(
          registration: registration,
          challenge: challenge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 16.0
        : 24.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                28,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Join Origami', style: serifTitle(36)),
                    const SizedBox(height: 8),
                    const Text(
                      'We will email you a 6-digit verification code.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 28),
                    _label('Display name'),
                    TextFormField(
                      key: const Key('signupNameField'),
                      controller: _nameController,
                      enabled: !session.isBusy,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        hintText: 'Paper Artist',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 2) {
                          return 'Enter at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Username'),
                    TextFormField(
                      key: const Key('signupHandleField'),
                      controller: _handleController,
                      enabled: !session.isBusy,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9._]'),
                        ),
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'paperartist',
                        prefixText: '@ ',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!RegExp(r'^[A-Za-z0-9._]{3,30}$').hasMatch(text)) {
                          return 'Use 3-30 letters, numbers, dots or underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Email'),
                    TextFormField(
                      key: const Key('signupEmailField'),
                      controller: _emailController,
                      enabled: !session.isBusy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'your@email.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(text)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Password'),
                    TextFormField(
                      key: const Key('signupPasswordField'),
                      controller: _passwordController,
                      enabled: !session.isBusy,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters',
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
                        if ((value ?? '').length < 8) {
                          return 'Password must contain at least 8 characters';
                        }
                        if ((value ?? '').length > 72) {
                          return 'Password cannot exceed 72 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Confirm password'),
                    TextFormField(
                      key: const Key('signupConfirmPasswordField'),
                      controller: _confirmPasswordController,
                      enabled: !session.isBusy,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!session.isBusy) _continue();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter the password again',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) => value != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 26),
                    PrimaryButton(
                      label: session.isBusy
                          ? 'Sending code...'
                          : 'Send verification code',
                      onPressed: session.isBusy ? null : _continue,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: session.isBusy
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Already have an account? Log in'),
                      ),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.registration,
    required this.challenge,
    super.key,
  });

  final RegistrationDraft registration;
  final OtpChallenge challenge;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  Timer? _timer;
  late int _resendSeconds;
  late int _expirySeconds;

  @override
  void initState() {
    super.initState();
    _applyChallenge(widget.challenge);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
        if (_expirySeconds > 0) _expirySeconds--;
      });
    });
  }

  void _applyChallenge(OtpChallenge challenge) {
    _resendSeconds = challenge.resendIn;
    _expirySeconds = challenge.expiresIn;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_expirySeconds <= 0) {
      showAppMessage(context, 'This code has expired. Request a new one.');
      return;
    }
    final session = AuthScope.of(context, listen: false);
    final succeeded = await session.verifyRegistration(
      registration: widget.registration,
      otp: _otpController.text,
    );
    if (!mounted) return;
    if (!succeeded) {
      showAppMessage(
        context,
        session.errorMessage ?? 'Could not verify this code.',
      );
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.newsfeed, (route) => false);
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    final session = AuthScope.of(context, listen: false);
    final challenge = await session.requestRegistrationOtp(
      widget.registration.email,
    );
    if (!mounted) return;
    if (challenge == null) {
      showAppMessage(
        context,
        session.errorMessage ?? 'Could not resend the verification code.',
      );
      return;
    }
    setState(() {
      _applyChallenge(challenge);
      _otpController.clear();
    });
    showAppMessage(context, 'A new code was sent');
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 72,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: 20),
                    Text('Check your email', style: serifTitle(31)),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the 6-digit code sent to\n${widget.registration.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      key: const Key('registrationOtpField'),
                      controller: _otpController,
                      enabled: !session.isBusy,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                      ),
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        hintText: '000000',
                        counterText: '',
                      ),
                      maxLength: 6,
                      validator: (value) => (value ?? '').length != 6
                          ? 'Enter all 6 digits'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!session.isBusy) _verify();
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _expirySeconds > 0
                          ? 'Code expires in ${_formatSeconds(_expirySeconds)}'
                          : 'Code expired',
                      style: TextStyle(
                        color: _expirySeconds > 0
                            ? AppColors.mutedText
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: session.isBusy
                          ? 'Verifying...'
                          : 'Verify and create account',
                      onPressed: session.isBusy ? null : _verify,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: session.isBusy || _resendSeconds > 0
                          ? null
                          : _resend,
                      child: Text(
                        _resendSeconds > 0
                            ? 'Resend code in ${_resendSeconds}s'
                            : 'Resend code',
                      ),
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

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}
