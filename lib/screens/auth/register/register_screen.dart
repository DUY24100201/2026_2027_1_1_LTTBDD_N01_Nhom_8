import 'package:flutter/material.dart';
import 'package:lttbdd_nhom8/core/constants/app_colors.dart';



class RegisterScreen extends StatefulWidget {
    const RegisterScreen({super.key});

    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
    final nameController = TextEditingController(); 
    final emailController = TextEditingController();
    final passwordController = TextEditingController(); 
    final confirmController = TextEditingController(); 

    bool hidePassword = true;

    void register() {

  // Kiểm tra các ô nhập có bị bỏ trống không.
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty) {

            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ thông tin!'),
                ),
            );

        } else if (passwordController.text != confirmController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mật khẩu không khớp!')
                ),
            );

        } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đăng ký thành công!'),
                ),
            );
        }
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
                                onPressed: register, //goi  ham dki  khi nhan nut 

                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                ),

                                child: const Text(
                                    'Đăng kí',
                                    style: TextStyle(color: AppColors.white),
                                ),
                            ),
                        ),

                        TextButton(
                            onPressed: () {
                                Navigator.pop(context); // quay lai login
                            },

                            child: const Text(
                                'Đã có tài khoản? Đăng nhập'
                            ),
                        ),

                    ],
                ),
            ),
         ),
    
    );
  }
}