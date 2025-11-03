
// ignore: file_names
import 'package:flutter/material.dart';
import 'auth_service.dart'; // 💡 IMPORT AUTH SERVICE

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ✅ Đổi tên + Thêm controller
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController =
      TextEditingController(text: "PATIENT");
  final TextEditingController roleLevelController =
      TextEditingController(text: "BASIC");

  bool _obscure = true;
  bool _loading = false;

  // ✅ Sử dụng AuthService
  final AuthService _authService = AuthService();

  // ⛔️ Xóa baseUrl (đã chuyển vào AuthService)

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    roleController.dispose();
    roleLevelController.dispose();
    super.dispose();
  }

  // ✅ REFACTOR HÀM _register
  Future<void> _register() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final role = roleController.text.trim();
    final roleLevel = roleLevelController.text.trim();

    if (username.isEmpty || password.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Vui lòng điền Họ tên, Username & Mật khẩu")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ Gọi hàm register từ AuthService
      final String? error = await _authService.register(
        fullName,
        username, // Dùng làm 'account'
        password,
        role,
        roleLevel,
      );

      if (error == null) {
        // Thành công
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đăng ký thành công! Vui lòng đăng nhập.")),
        );
        if (mounted) Navigator.pop(context);
      } else {
        // Lỗi
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $error")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi không xác định: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                      image: AssetImage("assets/1.png"), fit: BoxFit.cover),
                ),
                child: Column(
                  children: [
                    // ignore: prefer_const_constructors
                    Icon(Icons.person_add_alt_1, size: 80, color: primaryColor),
                    const SizedBox(height: 10),
                    // ignore: prefer_const_constructors
                    Text("CREATE ACCOUNT",
                        // ignore: prefer_const_constructors
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                    const SizedBox(height: 6),
                    Text("Register as a Patient",
                        style: TextStyle(
                            // ignore: deprecated_member_use
                            color: primaryColor.withOpacity(0.8),
                            fontSize: 16)),
                  ],
                ),
              ),

              // ✅ THÊM TRƯỜNG "HỌ TÊN"
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
                controller: usernameController, // ✅ Đổi tên controller
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
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              // Role
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text("Role (optional)",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ),
              _buildInputField(
                controller: roleController,
                icon: Icons.shield_outlined,
                hint: "PATIENT / DOCTOR ...",
              ),

              // Role Level
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text("Role level (optional)",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ),
              _buildInputField(
                controller: roleLevelController,
                icon: Icons.stacked_bar_chart_outlined,
                hint: "BASIC / ADVANCED ...",
              ),

              const SizedBox(height: 20),

              // Button
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
                    // ignore: prefer_const_constructors
                    child: Text("ALREADY HAVE AN ACCOUNT?",
                        // ignore: prefer_const_constructors
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI helpers (Không đổi)
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
              child: Icon(icon, color: Colors.grey)),
          Container(
              height: 30.0,
              width: 1.0,
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.5),
              margin: const EdgeInsets.only(right: 10.0)),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: suffix),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Spacer(),
            CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(icon, color: color)),
          ],
        ),
      ),
    );
  }
}