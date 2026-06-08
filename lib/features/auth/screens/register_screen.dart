import 'package:flutter/material.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/features/auth/logic/auth_controller.dart';

/// Màn hình Đăng ký tài khoản
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Password strength
  int _passwordStrength = 0; // 0-4

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();

    _passwordCtrl.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final pw = _passwordCtrl.text;
    int strength = 0;
    if (pw.length >= 6) strength++;
    if (pw.length >= 10) strength++;
    if (pw.contains(RegExp(r'[A-Z]'))) strength++;
    if (pw.contains(RegExp(r'[0-9!@#\$%^&*]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Vui lòng đồng ý với Điều khoản sử dụng.');
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authController.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      // Hiển thị dialog chào mừng rồi navigate
      await _showWelcomeDialog();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.newsfeed,
          (route) => false,
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = _authController.errorMessage;
      });
    }
  }

  Future<void> _showWelcomeDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Chào mừng!',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tài khoản của bạn đã được tạo thành công.\nHãy bắt đầu hành trình Origami! 🦢',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Bắt đầu ngay!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildBackButton(),
                        const SizedBox(height: 24),
                        _buildHeader(),
                        const SizedBox(height: 36),
                        _buildForm(),
                        const SizedBox(height: 28),
                        _buildRegisterButton(),
                        const SizedBox(height: 28),
                        _buildLoginLink(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: _RegisterBgPainter()),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tạo tài khoản\nmới ✨',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tham gia cộng đồng Origami và chia sẻ\nnhững tác phẩm nghệ thuật của bạn.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error banner
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // Full Name
          _buildLabel('Tên hiển thị'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _errorMessage = null),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Nguyễn Văn A',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên';
              if (val.trim().length < 2) return 'Tên phải có ít nhất 2 ký tự';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Email
          _buildLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _errorMessage = null),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
              if (!val.contains('@') || !val.contains('.')) return 'Email không hợp lệ';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password
          _buildLabel('Mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
              if (val.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
              return null;
            },
          ),

          // Password strength bar
          if (_passwordCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPasswordStrengthBar(),
          ],

          const SizedBox(height: 20),

          // Confirm password
          _buildLabel('Xác nhận mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
              if (val != _passwordCtrl.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Terms & Conditions
          GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: _acceptTerms ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: _acceptTerms ? AppColors.primary : AppColors.textHint,
                      width: 1.5,
                    ),
                  ),
                  child: _acceptTerms
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản sử dụng',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' và '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' của Origami.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    final labels = ['Rất yếu', 'Yếu', 'Trung bình', 'Mạnh'];
    final colors = [
      const Color(0xFFEF5350),
      const Color(0xFFFF7043),
      const Color(0xFFFFCA28),
      AppColors.success,
    ];

    final idx = (_passwordStrength - 1).clamp(0, 3);
    final label = _passwordStrength > 0 ? labels[idx] : '';
    final color = _passwordStrength > 0 ? colors[idx] : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < _passwordStrength ? color : AppColors.primaryLight,
                ),
              ),
            );
          }),
        ),
        if (_passwordStrength > 0) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8A0BF), Color(0xFFBE6F9A)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Đăng nhập',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: AppColors.textPrimary,
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textHint,
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.textHint, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
    );
  }
}

// ─────────────────────────────────────────
// Background Painter
// ─────────────────────────────────────────
class _RegisterBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFF8BBD0).withOpacity(0.45);
    canvas.drawCircle(Offset(-50, -50), 180, paint);

    paint.color = const Color(0xFFFCE4EC).withOpacity(0.55);
    canvas.drawCircle(Offset(size.width + 50, size.height + 30), 200, paint);

    paint.color = const Color(0xFFE8A0BF).withOpacity(0.12);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
