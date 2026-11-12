import 'package:material_ui/material_ui.dart';
import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/screens/auth/login/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
  onRegister;

  const RegisterScreen({super.key, this.onLogin, this.onRegister});

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
          builder: (_) => LoginScreen(
            onLogin: widget.onLogin,
            onRegister: widget.onRegister,
            initialMessage: 'Tạo tài khoản thành công. Vui lòng đăng nhập.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Đăng ký thất bại: $error');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override //giai phong bo nho
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
        title: const Text('Đăng ký'), // Tên màn hình.
        backgroundColor: AppColors.background, // Màu thanh tiêu đề.
        foregroundColor: AppColors.white, // Màu chữ và biểu tượng.
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              TextField(
                controller: nameController,

                decoration: InputDecoration(
                  hintText: 'Họ và tên',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                style: const TextStyle(color: AppColors.white), // Màu chữ.
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                style: const TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                style: const TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: confirmController, //lay mk nhap lai
                obscureText: hidePassword,
                decoration: InputDecoration(
                  hintText: 'Xác nhận mật khẩu',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                style: const TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: isSubmitting ? null : register,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                          'Đăng kí',
                          style: TextStyle(color: AppColors.white),
                        ),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pop(context); // quay lai login
                },

                child: const Text('Đã có tài khoản? Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
