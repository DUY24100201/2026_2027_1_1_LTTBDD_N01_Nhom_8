
import 'package:material_ui/material_ui.dart';
import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/screens/home/home_screen.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';
import 'package:lttbdd_nhom8/screens/auth/register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
      onRegister;
  final Future<void> Function()? onLogout;
  final String? initialMessage;

  const LoginScreen({
    super.key,
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.initialMessage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final message = widget.initialMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(message);
      });
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.trim().isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin!');
      return;
    }

    final onLogin = widget.onLogin;

    if (onLogin == null) {
      _showMessage(
        'Chưa cấu hình backend/API xác thực. Không thể đăng nhập.',
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final authenticated = await onLogin(email, password);

      if (!mounted) return;

      if (!authenticated) {
        _showMessage('Thông tin đăng nhập không chính xác.');
        return;
      }

      final navigator = Navigator.of(context);

      await navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => IntroDialogPage(
            screenId: 'home',
            child: HomeScreen(
              onLogout: () async {
                await widget.onLogout?.call();
                await navigator.pushAndRemoveUntil<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => IntroDialogPage(
                      screenId: 'login',
                      child: LoginScreen(
                        onLogin: widget.onLogin,
                        onRegister: widget.onRegister,
                        onLogout: widget.onLogout,
                      ),
                    ),
                  ),
                  (_) => false,
                );
              },
            ),
          ),
        ),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Đăng nhập thất bại: $error');
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  vertical: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // NÚT QUAY LẠI
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // LOGO
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/imgs/logo.png',
                              width: 105,
                              height: 105,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Melody',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Đăng nhập để tiếp tục thưởng thức âm nhạc.',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // EMAIL
                    _buildLabel('Email'),
                    const SizedBox(height: 10),

                    _buildInput(
                      controller: emailController,
                      hint: 'Nhập email của bạn',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 22),

                    // MẬT KHẨU
                    _buildLabel('Mật khẩu'),
                    const SizedBox(height: 10),

                    _buildInput(
                      controller: passwordController,
                      hint: 'Nhập mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: hidePassword,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // QUÊN MẬT KHẨU
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showMessage(
                            'Chức năng quên mật khẩu đang được phát triển.',
                          );
                        },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // NÚT ĐĂNG NHẬP
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
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
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ĐĂNG KÝ
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => IntroDialogPage(
                                screenId: 'register',
                                child: RegisterScreen(
                                  onLogin: widget.onLogin,
                                  onRegister: widget.onRegister,
                                  onLogout: widget.onLogout,
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(color: AppColors.grey),
                            children: [
                              TextSpan(
                                text: 'Đăng ký',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
          color: AppColors.primary,
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
