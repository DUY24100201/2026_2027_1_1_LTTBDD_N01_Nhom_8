
import 'package:material_ui/material_ui.dart';
import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/screens/auth/login/login_screen.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';

class RegisterScreen extends StatefulWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
      onRegister;
  final Future<void> Function()? onLogout;

  const RegisterScreen({
    super.key,
    this.onLogin,
    this.onRegister,
    this.onLogout,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool hidePassword = true;
  bool isSubmitting = false;

  Future<void> register() async {
    if (isSubmitting) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.trim().isEmpty ||
        confirmController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin!');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Mật khẩu phải có ít nhất 8 ký tự.');
      return;
    }

    if (password.length > 128) {
      _showMessage('Mật khẩu không được dài quá 128 ký tự.');
      return;
    }

    if (password != confirmController.text) {
      _showMessage('Mật khẩu không khớp!');
      return;
    }

    final onRegister = widget.onRegister;

    if (onRegister == null) {
      _showMessage(
        'Chưa cấu hình backend/API xác thực. Không thể tạo tài khoản.',
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final registered = await onRegister(name, email, password);

      if (!mounted) return;

      if (!registered) {
        _showMessage('Không thể tạo tài khoản. Vui lòng kiểm tra thông tin.');
        return;
      }

      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => IntroDialogPage(
            screenId: 'login',
            child: LoginScreen(
              onLogin: widget.onLogin,
              onRegister: widget.onRegister,
              onLogout: widget.onLogout,
              initialMessage: 'Tạo tài khoản thành công. Vui lòng đăng nhập.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Đăng ký thất bại: $error');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 25),

                    // LOGO
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/imgs/logo.png',
                              width: 85,
                              height: 85,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Tạo tài khoản',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tham gia Melody và tận hưởng âm nhạc',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    // HỌ VÀ TÊN
                    _buildLabel('Họ và tên'),
                    const SizedBox(height: 9),
                    _buildInput(
                      controller: nameController,
                      hint: 'Nhập họ và tên',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 20),

                    // EMAIL
                    _buildLabel('Email'),
                    const SizedBox(height: 9),
                    _buildInput(
                      controller: emailController,
                      hint: 'Nhập địa chỉ email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // MẬT KHẨU
                    _buildLabel('Mật khẩu'),
                    const SizedBox(height: 9),
                    _buildInput(
                      controller: passwordController,
                      hint: 'Nhập mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: hidePassword,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // XÁC NHẬN MẬT KHẨU
                    _buildLabel('Xác nhận mật khẩu'),
                    const SizedBox(height: 9),
                    _buildInput(
                      controller: confirmController,
                      hint: 'Nhập lại mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: hidePassword,
                    ),

                    const SizedBox(height: 30),

                    // NÚT ĐĂNG KÝ
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Đăng ký',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CHUYỂN ĐẾN ĐĂNG NHẬP
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Đã có tài khoản? Đăng nhập',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Melody Music Player',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.grey,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.grey,
          size: 21,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}
