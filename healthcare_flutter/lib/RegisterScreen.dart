// ignore: file_names
import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (fullName.isEmpty || username.isEmpty || password.isEmpty || confirm.isEmpty) {
      _toast("⚠️ Vui lòng điền đầy đủ Họ tên, Tên đăng nhập, Mật khẩu và Nhập lại mật khẩu");
      return;
    }
    if (password.length < 6) {
      _toast("🔐 Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }
    if (password != confirm) {
      _toast("❌ Mật khẩu nhập lại không khớp");
      return;
    }

    setState(() => _loading = true);

    try {
      // Giữ nguyên AuthService hiện tại: truyền ngầm PATIENT/BASIC
      final String? error = await _authService.register(
        fullName,
        username,
        password,
        "PATIENT", // ẩn trên UI, cố định cho bệnh nhân
        "BASIC",   // ẩn trên UI, mặc định
      );

      if (error == null) {
        _toast("✅ Đăng ký thành công! Vui lòng đăng nhập.");
        if (mounted) Navigator.pop(context);
      } else {
        _toast("❌ $error");
      }
    } catch (e) {
      _toast("❌ Lỗi không xác định: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1976D2);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 80, bottom: 60),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/1.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_add_alt_1, size: 80, color: primaryColor),
                    const SizedBox(height: 10),
                    Text(
                      "CREATE PATIENT ACCOUNT",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Register as a Patient",
                      style: TextStyle(
                        color: primaryColor.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Full name
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text("Full Name",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ),
              _buildInputField(
                controller: fullNameController,
                icon: Icons.badge_outlined,
                hint: "Enter your full name",
              ),

              // Username
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text("Username",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ),
              _buildInputField(
                controller: usernameController,
                icon: Icons.person_outline,
                hint: "Enter username",
              ),

              // Password
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text("Password",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ),
              _buildInputField(
                controller: passwordController,
                icon: Icons.lock_outline,
                hint: "Enter password",
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              // Confirm password
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text("Confirm Password",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ),
              _buildInputField(
                controller: confirmPasswordController,
                icon: Icons.lock_reset_outlined,
                hint: "Re-enter password",
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 20),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMainButton(
                      text: "REGISTER",
                      color: primaryColor,
                      icon: Icons.arrow_forward,
                      onPressed: _register,
                    ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "ALREADY HAVE AN ACCOUNT?",
                      style: TextStyle(
                        color: primaryColor,
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
    );
  }

  // UI helpers
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
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Icon(icon, color: Colors.grey),
          ),
          Container(
            height: 30.0,
            width: 1.0,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
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
