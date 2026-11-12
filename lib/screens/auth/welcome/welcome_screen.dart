
import 'package:flutter/material.dart';
import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import '../login/login_screen.dart';


class WelcomeScreen extends StatelessWidget {
  // Tạo màn hình chào mừng WelcomeScreen.

  const WelcomeScreen({super.key});
  // Constructor của màn hình.

  @override
  Widget build(BuildContext context) {
    // Hàm xây dựng giao diện màn hình chào mừng.

    return Scaffold(
      backgroundColor: AppColors.background, // Scaffold tạo khung màn hình cơ bản.
    

      body: SafeArea( // SafeArea tránh nội dung bị che bởi tai thỏ,
      

        child: Padding( // Padding tạo khoảng cách bên trong widget.

          padding: const EdgeInsets.all(25),
          // Cách đều 4 cạnh 25 pixel.

          child: Column(
            // Column sắp xếp các widget theo chiều dọc.

            children: [
              // Danh sách các thành phần giao diện.

              const Spacer(),
              // Tạo khoảng trống co giãn để đẩy nội dung xuống.

              // LOGO ỨNG DỤNG
              Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/imgs/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  const Text(
                      'Melody',
                        style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),

              const Spacer(),
              // Tạo khoảng trống co giãn giữa phần logo và giới thiệu.

              // TIÊU ĐỀ GIỚI THIỆU
              const Text(
                'Âm nhạc cho mọi khoảnh khắc',

                textAlign: TextAlign.center,
                // Căn giữa nội dung chữ.

                style: TextStyle(
                  fontSize: 25,
                  // Cỡ chữ 25.

                  fontWeight: FontWeight.bold,
                  // In đậm.

                  color: AppColors.white,
                  // Chữ màu trắng.
                ),
              ),

              const SizedBox(height: 12),
              // Khoảng cách 12 pixel.

              const Text(
                'Khám phá những giai điệu yêu thích '
                'và tận hưởng âm nhạc theo cách của bạn.',
                

                textAlign: TextAlign.center,
                // Căn giữa đoạn văn.

                style: TextStyle(
                  fontSize: 14,
                  // Cỡ chữ 14.

                  color: AppColors.white,
                  // Màu trắng hơi mờ.

                  height: 1.5,
                  // Chiều cao dòng bằng 1.5 lần cỡ chữ.
                ),
              ),

              const Spacer(),
              // Đẩy các nút xuống gần cuối màn hình.

              // NÚT ĐĂNG NHẬP
              SizedBox(
                // SizedBox dùng để cố định kích thước widget.

                width: double.infinity,
                // Chiếm toàn bộ chiều rộng có thể sử dụng.

                height: 52,
                // Chiều cao nút 52 pixel.

                child: ElevatedButton(
                  // ElevatedButton là nút bấm có nền.

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    // Thiết lập kiểu dáng nút.

                    backgroundColor: AppColors.primary,
                    // Nền nút màu tím.

                    foregroundColor: Colors.white,
                    // Màu chữ và biểu tượng màu trắng.

                    shape: RoundedRectangleBorder(
                      // Tạo hình dạng nút.

                      borderRadius: BorderRadius.circular(30),
                      // Bo tròn góc nút 30 pixel.
                    ),
                  ),

                  child: const Text(
                    'Đăng nhập',
                    // Chữ hiển thị trên nút.

                    style: TextStyle(fontSize: 16),
                    // Cỡ chữ 16.
                  ),
                ),
              ),

              const SizedBox(height: 15),
              // Khoảng cách giữa hai nút là 15 pixel.

              // NÚT ĐĂNG KÝ
              SizedBox(
                width: double.infinity,
                // Nút chiếm toàn bộ chiều rộng.

                height: 52,
                // Chiều cao 52 pixel.

                child: OutlinedButton(
                  // OutlinedButton là nút có viền, nền trong suốt.

                  onPressed: () {
                    // Xử lý khi người dùng nhấn Đăng ký.

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bạn đã chọn Đăng ký'),
                        // Hiển thị thông báo khi nhấn nút.
                      ),
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    // Thiết lập kiểu dáng nút.

                    foregroundColor: AppColors.white,
                    // Màu chữ trắng.

                    side: const BorderSide(
                      color: AppColors.primary,
                      // Màu đường viền tím.
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      // Bo tròn góc nút.
                    ),
                  ),

                  child: const Text(
                    'Đăng ký',
                    // Nội dung hiển thị trên nút.

                    style: TextStyle(fontSize: 16),
                    // Cỡ chữ 16.
                  ),
                ),
              ),

              const SizedBox(height: 25),
              // Khoảng cách 25 pixel.

              const Text(
                'Melody Music Player',
                // Dòng chữ cuối màn hình.

                style: TextStyle(
                  color: AppColors.grey,
                  // Màu chữ xám nhạt.

                  fontSize: 12,
                  // Cỡ chữ 12.
                ),
              ),

              const SizedBox(height: 15),
              // Tạo khoảng trống cuối màn hình.
            ],
          ),
        ),
      ),
    );
  }
}
