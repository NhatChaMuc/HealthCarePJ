import 'dart:async'; // ✅ SỬA LỖI Ở ĐÂY: dart:async
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 💡 Cần import http để dùng Exception của nó
import 'RegisterScreen.dart';
import 'auth_service.dart'; 
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final Color primaryColor;
  final Color backgroundColor;
  final AssetImage backgroundImage;

  const LoginScreen({
    super.key,
    this.primaryColor = const Color(0xFF1976D2),
    this.backgroundColor = Colors.white,
    this.backgroundImage = const AssetImage("assets/1.png"),
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _loading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  // ================= XỬ LÝ LOGIN (ĐÃ SỬA LỖI) =================
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _loading = true);

    String? errorMessage;

    try {
      final result = await _authService.login(username, password);

      if (result.containsKey('error')) {
        errorMessage = result['error'].toString();
      } else {
        final token = result['token'] ?? "";
        final fullName = result['fullName'] ?? username;
        final role = result['role'] ?? "PATIENT";

        // ignore: avoid_print
        print("✅ Login successful - Token: $token");
        // ignore: avoid_print
        print("👤 User: $fullName ($role)");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đăng nhập thành công!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              fullName: fullName,
              role: role,
              token: token,
            ),
          ),
        );
        return; 
      }
    } on TimeoutException {
      errorMessage = "⏱️ Máy chủ không phản hồi. Vui lòng thử lại sau.";
    } on http.ClientException { // ✅ SỬA LỖI Ở ĐÂY: Thêm 'http.'
      errorMessage = "🔌 Không thể kết nối tới máy chủ. Kiểm tra IP/mạng.";
    } catch (e) {
      errorMessage = "💥 Lỗi không xác định: $e";
    }

    // ignore: unnecessary_null_comparison
    if (errorMessage != null && mounted) {
      // ignore: avoid_print
      print("❌ Login failed: $errorMessage");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ $errorMessage"),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  // ================= GIAO DIỆN (Không đổi) =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: widget.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // HEADER
                ClipPath(
                  clipper: MyClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: widget.backgroundImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 100.0, bottom: 100.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.health_and_safety_outlined,
                            size: 80, color: widget.primaryColor),
                        const SizedBox(height: 10),
                        Text(
                          "HEALTH LIFE",
                          style: TextStyle(
                            fontSize: 35.0,
                            fontWeight: FontWeight.bold,
                            color: widget.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Login to your account",
                          style: TextStyle(
                            fontSize: 15.0,
                            // ignore: deprecated_member_use
                            color: widget.primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Username
                const Padding(
                  padding: EdgeInsets.only(left: 40.0, top: 10),
                  child: Text(
                    "Username",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0),
                  ),
                ),
                _buildInputField(
                  controller: _usernameController,
                  icon: Icons.person_outline,
                  hint: "Enter username",
                ),

                // Password
                const Padding(
                  padding: EdgeInsets.only(left: 40.0, top: 10),
                  child: Text(
                    "Password",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0),
                  ),
                ),
                _buildInputField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hint: "Enter your password",
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 20),

                // LOGIN BUTTON
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMainButton(
                        text: "LOGIN",
                        color: widget.primaryColor,
                        icon: Icons.arrow_forward,
                        onPressed: _handleLogin,
                      ),

                // REGISTER LINK
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "DON'T HAVE AN ACCOUNT?",
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD (Không đổi) =================
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Icon(icon, color: Colors.grey),
          ),
          Container(
            height: 30.0,
            width: 1.0,
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.5),
            margin: const EdgeInsets.only(right: 10.0),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: suffix,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MAIN BUTTON (Không đổi) =================
  Widget _buildMainButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(icon, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= CLIPPER HEADER (Không đổi) =================
class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()
      ..lineTo(size.width, 0.0)
      ..lineTo(size.width, size.height * 0.85)
      ..arcToPoint(
        Offset(0.0, size.height * 0.85),
        radius: const Radius.elliptical(50.0, 10.0),
      )
      ..lineTo(0.0, 0.0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

