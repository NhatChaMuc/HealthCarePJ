import 'package:flutter/material.dart';
import 'auth_service.dart'; // Đảm bảo đường dẫn import đúng với project của bạn

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller để lấy dữ liệu nhập vào
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Biến trạng thái ẩn/hiện mật khẩu
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

  // Hàm xử lý đăng ký
  Future<void> _register() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    // 1. Kiểm tra dữ liệu đầu vào
    if (fullName.isEmpty || username.isEmpty || password.isEmpty || confirm.isEmpty) {
      _toast("⚠️ Vui lòng điền đầy đủ thông tin!");
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
      // 2. Gửi về Backend (Gán cứng PATIENT và BASIC)
      final String? error = await _authService.register(
        fullName,
        username,
        password,
        "PATIENT", // <--- QUAN TRỌNG: Luôn luôn là PATIENT
        "BASIC",   // <--- Mặc định
      );

      if (error == null) {
        // Thành công
        _toast("✅ Đăng ký thành công! Vui lòng đăng nhập.");
        if (mounted) Navigator.pop(context); // Quay về màn hình Login
      } else {
        // Thất bại (User tồn tại, lỗi mạng...)
        _toast("❌ $error");
      }
    } catch (e) {
      _toast("❌ Lỗi hệ thống: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1976D2); // Màu xanh chủ đạo

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 70, color: primaryColor),
                    const SizedBox(height: 15),
                    const Text(
                      "CREATE PATIENT ACCOUNT",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Sign up to book appointments",
                      style: TextStyle(
                        color: primaryColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- FORM INPUT ---
              
              // 1. Full Name
              _buildLabel("Full Name"),
              _buildInputField(
                controller: fullNameController,
                icon: Icons.badge_outlined,
                hint: "Nguyen Van A",
              ),

              // 2. Username
              _buildLabel("Username"),
              _buildInputField(
                controller: usernameController,
                icon: Icons.person_outline,
                hint: "username123",
              ),

              // 3. Password
              _buildLabel("Password"),
              _buildInputField(
                controller: passwordController,
                icon: Icons.lock_outline,
                hint: "••••••",
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              // 4. Confirm Password
              _buildLabel("Confirm Password"),
              _buildInputField(
                controller: confirmPasswordController,
                icon: Icons.lock_reset,
                hint: "••••••",
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 30),

              // --- BUTTON REGISTER ---
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _register,
                        child: const Text(
                          "REGISTER",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

              // --- LOGIN LINK ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Login Now",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // Widget Label nhỏ phía trên ô nhập
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, top: 15, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget Ô nhập liệu
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
