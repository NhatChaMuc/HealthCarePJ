import 'package:flutter/material.dart';
import 'admin_service.dart';

class CreateNurseScreen extends StatefulWidget {
  final String adminToken;

  const CreateNurseScreen({super.key, required this.adminToken});

  @override
  State<CreateNurseScreen> createState() => _CreateNurseScreenState();
}

class _CreateNurseScreenState extends State<CreateNurseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // ✅ Thêm controller mới
  final _departmentController = TextEditingController();

  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    // ✅ Nhớ dispose controller mới
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _createNurse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      // ✅ Gửi thêm department
      final result = await _adminService.createNurse(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        department: _departmentController.text.trim(),
        adminToken: widget.adminToken,
      );

      setState(() {
        _message = "✅ $result";
      });

      _formKey.currentState?.reset();
      _fullNameController.clear();
      _usernameController.clear();
      _passwordController.clear();
      // ✅ Xóa controller mới
      _departmentController.clear();
    } catch (e) {
      setState(() {
        _message = "❌ ${e.toString().replaceFirst('Exception: ', '')}";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👩‍⚕️ Tạo tài khoản Y tá mới",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Họ tên
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: "Họ và tên",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng nhập họ tên" : null,
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Tên đăng nhập",
                prefixIcon: Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng nhập tên đăng nhập" : null,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Vui lòng nhập mật khẩu";
                } else if (v.length < 5) {
                  return "Mật khẩu phải ít nhất 5 ký tự";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ✅ Thêm trường Khoa
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: "Khoa công tác (ví dụ: Khoa Điều dưỡng)",
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? "Vui lòng nhập khoa công tác"
                  : null,
            ),
            const SizedBox(height: 24),

            // Nút tạo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _createNurse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  _loading ? "Đang xử lý..." : "Tạo tài khoản",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.contains("✅")
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _message!.contains("✅")
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    fontSize: 16,
                    color: _message!.contains("✅")
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
