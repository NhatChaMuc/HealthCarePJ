import 'package:flutter/material.dart';
import 'login_screen.dart'; // 👉 Nhập (import) màn hình đăng nhập để chuyển đến sau khi splash kết thúc

// ==========================
// 🌊 MÀN HÌNH CHÀO (SplashScreen)
// ==========================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ==========================
// 🔄 State điều khiển hoạt ảnh
// ==========================
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Bộ điều khiển hoạt ảnh chính
  late final AnimationController _controller;

  // Các hoạt ảnh khác nhau (độ mờ, phóng to, thanh tiến trình, trượt chữ)
  late final Animation<double> _fade, _scale, _progress;
  late final Animation<Offset> _slideText, _slideSlogan;

  @override
  void initState() {
    super.initState();

    // Tạo AnimationController chạy trong 3 giây
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward(); // Bắt đầu chạy ngay khi mở màn hình

    // Hoạt ảnh mờ dần hiện logo
    _fade = _tween(0.0, 1.0, const Interval(0.0, 0.7, curve: Curves.easeOut));

    // Hoạt ảnh phóng to logo từ nhỏ → to (hiệu ứng đàn hồi)
    _scale = _tween(0.5, 1.0, const Interval(0.0, 0.8, curve: Curves.elasticOut));

    // Hoạt ảnh trượt lên của tiêu đề “Health Life”
    _slideText = _offsetTween(const Offset(0, 0.5), const Interval(0.4, 0.9));

    // Hoạt ảnh trượt lên của dòng slogan
    _slideSlogan = _offsetTween(const Offset(0, 0.8), const Interval(0.6, 1.0));

    // Hoạt ảnh thanh tiến trình (LinearProgressIndicator)
    _progress = _tween(0.0, 1.0, Curves.linear);

    // Khi hoạt ảnh chạy xong → chuyển sang màn hình đăng nhập
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  // Hàm tạo hoạt ảnh giá trị (tween) cho các loại double (opacity, scale, progress)
  Animation<double> _tween(double begin, double end, Curve curve) =>
      Tween(begin: begin, end: end)
          .animate(CurvedAnimation(parent: _controller, curve: curve));

  // Hàm tạo hoạt ảnh vị trí (Offset) cho các đối tượng trượt lên
  Animation<Offset> _offsetTween(Offset begin, Interval interval) =>
      Tween(begin: begin, end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: interval));

  // Giải phóng tài nguyên khi rời màn hình
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==========================
  // 🖼️ GIAO DIỆN CHÍNH CỦA MÀN HÌNH CHÀO
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Nền là hình ảnh toàn màn hình
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/1.png'), // 📸 Ảnh nền trong thư mục assets
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Canh giữa dọc
            children: [
              // Hiệu ứng mờ dần và phóng to logo
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, // Hình tròn bao quanh logo
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.8), // Nền trắng mờ
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.2), // Bóng mờ logo
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    // Icon trung tâm – biểu tượng y tế
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.blue.shade700, // Màu xanh y tế
                      size: 100,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Hiệu ứng trượt lên cho tiêu đề ứng dụng
              SlideTransition(
                position: _slideText,
                child: const Text(
                  'Health Life',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black38,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Hiệu ứng trượt lên cho dòng slogan
              SlideTransition(
                position: _slideSlogan,
                child: Text(
                  'Sức khỏe của bạn, ưu tiên của chúng tôi',
                  style: TextStyle(
                    fontSize: 18,
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.9),
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Thanh tiến trình động thể hiện thời gian chuyển tiếp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _progress.value,
                    color: Colors.white,
                    // ignore: deprecated_member_use
                    backgroundColor: Colors.white.withOpacity(0.3),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Thông tin phiên bản ứng dụng
              const Text(
                'Version 1.0.0 · © 2025 Health Life App',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  shadows: [
                    Shadow(
                      blurRadius: 5,
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
