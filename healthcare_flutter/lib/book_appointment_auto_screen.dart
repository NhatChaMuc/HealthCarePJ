import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // ✅ FIX: SỬ DỤNG IMPORT CHÍNH XÁC

// ❌ LỚP AppConfig BỊ LỖI ĐÃ BỊ XÓA KHỎI ĐÂY

class BookAppointmentAutoScreen extends StatefulWidget {
  final String token;
  const BookAppointmentAutoScreen({super.key, required this.token});

  @override
  State<BookAppointmentAutoScreen> createState() =>
      _BookAppointmentAutoScreenState();
}

class _BookAppointmentAutoScreenState extends State<BookAppointmentAutoScreen> {
  int _step = 1;
  bool _submitting = false;

  final _form1Key = GlobalKey<FormState>();
  final _form2Key = GlobalKey<FormState>();

  // Step 1
  final _nameCtl = TextEditingController();
  final _birthCtl = TextEditingController(); // dd/MM/yyyy
  final _phoneCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  String _gender = "Nam";

  // Step 2
  DateTime? _preferredDate;
  String? _preferredWindow;
  final _reasonCtl = TextEditingController();

  // Step 3 (hiển thị kết quả)
  Map<String, dynamic>? _successData;

  // ========================= dọn dẹp controller =========================
  @override
  void dispose() {
    _nameCtl.dispose();
    _birthCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    _reasonCtl.dispose();
    super.dispose();
  }

  // ========================= helpers =========================
  void _showSnack(String msg) {
    if (!mounted) return; // Kiểm tra mounted trước khi dùng context
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _parseDate(String input) {
    try {
      final parts = input.split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  String _formatDMY(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final pick = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (pick != null) {
      _birthCtl.text = _formatDMY(pick);
    }
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final pick = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Chọn ngày hẹn mong muốn',
    );
    if (pick != null) setState(() => _preferredDate = pick);
  }

  // ========================= submit =========================
  Future<void> _submit() async {
    // SỬA LỖI:
    // Chỉ validate form của bước 2 (_form2Key).
    // _form1Key đã được validate khi nhấn "Tiếp Tục" ở bước 1.
    if (!_form2Key.currentState!.validate()) {
      _showSnack("⚠️ Vui lòng điền đầy đủ thông tin ở bước này.");
      return;
    }

    // Các kiểm tra còn lại giữ nguyên
    if (_preferredDate == null || _preferredWindow == null) {
      _showSnack("⚠️ Vui lòng chọn ngày và khung giờ hẹn.");
      return;
    }

    final birth = _parseDate(_birthCtl.text.trim());
    if (birth == null) {
      _showSnack("⚠️ Ngày sinh không hợp lệ (định dạng dd/MM/yyyy).");
      // Cân nhắc trả về bước 1 nếu ngày sinh sai
      // setState(() => _step = 1);
      return;
    }

    setState(() => _submitting = true);

    final body = {
      "patient": {
        "fullName": _nameCtl.text.trim(),
        "gender": _gender,
        "email": _emailCtl.text.trim(),
        "phone": _phoneCtl.text.trim(),
        "birthDate": birth.toIso8601String(),
      },
      "symptom": _reasonCtl.text.trim(),
      "preferredDate": _preferredDate!.toIso8601String(),
      "preferredWindow": _preferredWindow,
    };

    try {
      // ✅ FIX: GỌI ĐÚNG URL PRODUCTION
      final res = await http.post(
        // Lấy URL Production từ AppConfig chính
        Uri.parse('${AppConfig.ai}/auto-schedule'), 
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _successData = jsonDecode(res.body);
        setState(() => _step = 3);
      } else {
        _showSnack("❌ Lỗi server: HTTP ${res.statusCode}");
      }
    } catch (e) {
      // ✅ GHI NHẬN LỖI ĐỂ KIỂM TRA
      print("❌ Lỗi kết nối Appointment: $e");
      _showSnack("❌ Không thể kết nối đến máy chủ: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetAll() {
    _nameCtl.clear();
    _birthCtl.clear();
    _phoneCtl.clear();
    _emailCtl.clear();
    _reasonCtl.clear();
    _gender = "Nam";
    _preferredWindow = null;
    _preferredDate = null;
    _successData = null;
    setState(() => _step = 1);
  }

  // ========================= UI =========================
  @override
  Widget build(BuildContext context) {
    // Sử dụng SingleChildScrollView và ConstrainedBox để form không bị vỡ trên màn hình nhỏ
    // và căn giữa trên màn hình lớn.
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              // AnimatedSwitcher để chuyển bước mượt hơn
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper để AnimatedSwitcher biết widget nào cần hiển thị
  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildSuccessStep();
      default:
        return _buildStep1();
    }
  }

  // ========================= STEP 1 =========================
  Widget _buildStep1() => Form(
        key: _form1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Giúp Column co lại vừa đủ
          children: [
            const Text("Đặt Lịch Hẹn Khám Bệnh",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Bước 1 trên 3: Thông tin bệnh nhân",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildField("Họ và Tên", _nameCtl)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _birthCtl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Ngày Sinh",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                      hintText: "dd/MM/yyyy",
                    ),
                    onTap: _pickBirthDate,
                    validator: (v) => v == null || v.isEmpty
                        ? "Vui lòng chọn ngày sinh"
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: "Giới Tính",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Nam", child: Text("Nam")),
                      DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
                      DropdownMenuItem(value: "Khác", child: Text("Khác")),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Số Điện Thoại",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return "Vui lòng nhập Số Điện Thoại";
                      final onlyDigits = RegExp(r'^\+?\d{8,15}$');
                      return onlyDigits.hasMatch(v)
                          ? null
                          : "Số điện thoại không hợp lệ";
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Địa chỉ Email",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return "Vui lòng nhập Địa chỉ Email";
                final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
                return regex.hasMatch(v) ? null : "Email không hợp lệ";
              },
            ),
            const SizedBox(height: 24),
            _gradientButton("Tiếp Tục", onTap: () {
              if (_form1Key.currentState!.validate()) {
                _form1Key.currentState!.save();
                setState(() => _step = 2);
              }
            }),
          ],
        ),
      );

  // ========================= STEP 2 =========================
  Widget _buildStep2() => Form(
        key: _form2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Đặt Lịch Hẹn Khám Bệnh",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Bước 2 trên 3: Chi tiết lịch hẹn",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickPreferredDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Ngày Hẹn Mong Muốn",
                        border: const OutlineInputBorder(),
                        // Hiển thị lỗi nếu _preferredDate là null khi submit
                        errorText: (_submitting && _preferredDate == null)
                            ? 'Vui lòng chọn ngày'
                            : null,
                      ),
                      child: Text(
                        _preferredDate == null
                            ? "dd/MM/yyyy"
                            : _formatDMY(_preferredDate!),
                        style: TextStyle(
                          color: _preferredDate == null
                              ? Colors.black54
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _preferredWindow,
                    hint: const Text("Chọn khung giờ"),
                    decoration: const InputDecoration(
                      labelText: "Giờ Hẹn Mong Muốn",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "MORNING",
                        child: Text("Sáng (8h–11h30)"),
                      ),
                      DropdownMenuItem(
                        value: "AFTERNOON",
                        child: Text("Chiều (13h30–16h30)"),
                      ),
                      DropdownMenuItem(
                        value: "EVENING",
                        child: Text("Tối (17h30–20h)"),
                      ),
                    ],
                    onChanged: (v) => setState(() => _preferredWindow = v),
                    validator: (v) =>
                        v == null ? "Vui lòng chọn khung giờ" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonCtl,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.isEmpty ? "Vui lòng điền lý do khám." : null,
              decoration: const InputDecoration(
                labelText: "Lý do khám bệnh (Tóm tắt)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _whiteButton("Quay Lại",
                    onTap: () => setState(() => _step = 1)),
                const SizedBox(width: 16),
                // Sử dụng Flexible hoặc Expanded để button co dãn
                Expanded(
                  child: _gradientButton(
                    _submitting ? "Đang xử lý..." : "Xác Nhận Đặt Lịch",
                    onTap: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ========================= STEP 3 =========================
  Widget _buildSuccessStep() {
    final data = _successData ?? {};

    final patientName = (data["patientName"] ??
        data["patient_full_name"] ??
        _nameCtl.text) as String;

    String bookedText;
    if (data["appointmentDate"] != null && data["appointmentWindow"] != null) {
      try {
        final dt = DateTime.parse(data["appointmentDate"]);
        final win = data["appointmentWindow"];
        // Chuyển đổi window thành text
        String winText = win;
        if (win == "MORNING") winText = "Sáng";
        if (win == "AFTERNOON") winText = "Chiều";
        if (win == "EVENING") winText = "Tối";

        bookedText = "${_formatDMY(dt)} - $winText";
      } catch (_) {
        bookedText = data["appointmentDate"].toString();
      }
    } else if (_preferredDate != null) {
      bookedText = "${_formatDMY(_preferredDate!)} ${_preferredWindow ?? ''}";
    } else {
      bookedText = "N/A";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 12),
        const Text("Đặt Lịch Thành Công!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          "Cảm ơn bạn đã tin tưởng. Lịch hẹn của bạn đã được ghi nhận.",
          textAlign: TextAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _infoRow("Họ và Tên", (patientName.isEmpty ? "N/A" : patientName)),
        _infoRow("Ngày Hẹn", bookedText),
        _infoRow(
            "Số Điện Thoại", _phoneCtl.text.isEmpty ? "N/A" : _phoneCtl.text),
        _infoRow("Email", _emailCtl.text.isEmpty ? "N/A" : _emailCtl.text),
        _infoRow(
            "Lý do khám", _reasonCtl.text.isEmpty ? "N/A" : _reasonCtl.text),
        const SizedBox(height: 12),
        const Text(
          "Chúng tôi sẽ gửi thông tin xác nhận chi tiết qua email và tin nhắn SMS.\nVui lòng kiểm tra và có mặt trước 15 phút.",
          textAlign: TextAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _gradientButton("Đặt Lịch Hẹn Khác", onTap: _resetAll),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start, // Cho phép text dài
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            // Dùng Expanded để value tự động xuống hàng nếu quá dài
            Expanded(
              child: Text(
                value.isEmpty ? "N/A" : value,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );

  // ========================= Buttons & fields =========================
  Widget _buildField(String label, TextEditingController ctl) => TextFormField(
        controller: ctl,
        validator: (v) =>
            (v == null || v.isEmpty) ? "Vui lòng nhập $label" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _gradientButton(String text, {VoidCallback? onTap}) => Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onTap != null
                ? [const Color(0xFF007BFF), const Color(0xFF00C6FF)]
                : [Colors.grey, Colors.grey.shade400], // Màu khi disable
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );

  Widget _whiteButton(String text, {VoidCallback? onTap}) => Container(
        // width: 150, // Bỏ width cố định để linh hoạt hơn
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(text,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      );
}