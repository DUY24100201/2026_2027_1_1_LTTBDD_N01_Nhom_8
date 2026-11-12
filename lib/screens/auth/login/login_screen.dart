import 'package:material_ui/material_ui.dart';
import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/screens/home/home_screen.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';
import 'package:lttbdd_nhom8/screens/auth/register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
  onRegister;
  final String? initialMessage;

  const LoginScreen({
    super.key,
    this.onLogin,
    this.onRegister,
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
      _showMessage('Chưa cấu hình backend/API xác thực. Không thể đăng nhập.');
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
            child: HomeScreen(
              onLogout: () => navigator.pushAndRemoveUntil<void>(
                MaterialPageRoute<void>(
                  builder: (_) => LoginScreen(
                    onLogin: widget.onLogin,
                    onRegister: widget.onRegister,
                  ),
                ),
                (_) => false,
              ),
            ),
          ),
        ),
        (_) => false,
      );
    } catch (error) {
      if (mounted) _showMessage('Đăng nhập thất bại: $error');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Center(
                child: Column(
                  children: [
                    // LOGO ỨNG DỤNG
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25), // Bo tròn 25px
                      child: Image.asset(
                        'assets/imgs/logo.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // TÊN ỨNG DỤNG
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
              const SizedBox(height: 40),
              const Text(
                'Chào mừng trở lại!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để tiếp tục thưởng thức âm nhạc.',
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              const Text('Email', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập email của bạn',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Mật khẩu', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.grey,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Xử lý quên mật khẩu sau
                  },
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterScreen(
                          onLogin: widget.onLogin,
                          onRegister: widget.onRegister,
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
            ],
          ),
        ),
      ),
    );
  }
}
