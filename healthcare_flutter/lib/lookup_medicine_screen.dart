import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class LookupMedicineScreen extends StatefulWidget {
  final String token;
  const LookupMedicineScreen({super.key, required this.token});

  @override
  State<LookupMedicineScreen> createState() => _LookupMedicineScreenState();
}

class _LookupMedicineScreenState extends State<LookupMedicineScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<dynamic> _items = [];

  Future<void> _search() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });

    try {
      // ✅ Dùng AppConfig.ai theo yêu cầu
      final url = Uri.parse("${AppConfig.ai}/drug-info-full");

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'drug': name}),
      );

      // Debug (tuỳ chọn)
      // print('🔍 Response status: ${res.statusCode}');
      // print('🔍 Response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)); // ✅ Fix encoding
        final items = data['items'] ?? [];
        setState(() {
          if (items.isEmpty) {
            _error = data['message'] ?? "Không tìm thấy thông tin thuốc.";
          } else {
            _items = items;
          }
        });
      } else {
        String? err;
        try {
          final errorData = jsonDecode(utf8.decode(res.bodyBytes));
          err = errorData['error']?.toString();
        } catch (_) {}
        setState(() => _error =
            err ?? "Lỗi ${res.statusCode}: ${res.reasonPhrase ?? 'Không xác định'}");
      }
    } catch (e) {
      setState(() => _error = "Không thể kết nối đến máy chủ: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ NỀN TRẮNG theo yêu cầu
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.medication_outlined,
                  size: 48, color: Colors.blueAccent),
              const SizedBox(height: 10),
              const Text(
                "Tra cứu thông tin thuốc",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Nhập tên thuốc để nhận thông tin chi tiết từ AI.",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 30),

              // Ô nhập + nút tìm
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 48,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Nhập tên thuốc, ví dụ: Paracetamol",
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      elevation: 2,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Tìm kiếm",
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                letterSpacing: 0.3),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              if (_loading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Đang tìm kiếm thông tin thuốc..."),
                  ],
                )
              else if (_error != null)
                _errorWidget(_error!)
              else if (_items.isEmpty)
                _placeholderWidget()
              else
                _resultWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorWidget(String msg) => Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        ),
      );

  Widget _placeholderWidget() => Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: const [
            Icon(Icons.medical_services_outlined,
                size: 40, color: Colors.blueAccent),
            SizedBox(height: 10),
            Text(
              "Bắt đầu tra cứu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Sẵn sàng để khám phá thông tin chi tiết về các loại thuốc một cách nhanh chóng và hiệu quả.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );

  // --------------------------
  // 🌈 TIỆN ÍCH HIỂN THỊ MÀU
  // --------------------------
  Widget _coloredSection(String title, dynamic content, Color color) {
    // content có thể là String hoặc List
    if (content == null) return const SizedBox.shrink();
    String text;
    if (content is List) {
      text = content.map((e) => "• ${e.toString()}").join("\n");
    } else {
      text = content.toString().trim();
    }
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15.5, color: color)),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: const TextStyle(fontSize: 14.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Cho phép map nhiều key khác nhau từ backend (phòng trường hợp đặt tên biến thể)
  T? _pick<T>(Map obj, List<String> keys) {
    for (final k in keys) {
      if (obj[k] != null) return obj[k] as T;
    }
    return null;
  }

  Widget _resultWidget() => Column(
        children: _items.map((raw) {
          // Ép kiểu an toàn
          final Map<String, dynamic> item =
              (raw is Map<String, dynamic>) ? raw : {};

          // Các trường cơ bản
          final name = _pick<String>(item, ['Tên thuốc', 'Ten thuoc', 'name']) ?? 'Không rõ';
          final manufacturer =
              _pick<String>(item, ['Hãng sản xuất', 'Hang san xuat', 'manufacturer']) ??
                  'Không rõ';
          final summary = _pick(item, ['Tóm tắt bác sĩ', 'Tom tat bac si', 'summary']) ??
              '(Không có nội dung)';

          // Các mục nội dung cần tô màu
          final indications = _pick(item, ['Chỉ định', 'Chi dinh', 'Indications', 'Công dụng', 'Công dụng', 'Use', 'Uses']);
          final contraindications = _pick(item, ['Chống chỉ định', 'Chống chỉ định', 'Contraindications']);
          final sideEffects = _pick(item, ['Tác dụng phụ', 'Tác dụng phụ', 'Adverse effects', 'Side effects']);
          final dosage = _pick(item, ['Liều dùng', 'Liều dùng', 'Dosage', 'Dose']);
          final precautions = _pick(item, ['Thận trọng', 'Thận trọng', 'Lưu ý', 'ưu ý', 'Precautions', 'Warnings']);
          final interactions = _pick(item, ['Tương tác thuốc', 'Tương tác thuốc', 'Interactions']);

          return Container(
            width: MediaQuery.of(context).size.width * 0.8,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Hãng sản xuất: $manufacturer",
                    style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 10),
                const Divider(height: 24),

                // Tóm tắt (indigo)
                _coloredSection("Tóm tắt", summary, Colors.indigo),

                // Các mục có màu riêng
                _coloredSection("Chỉ định / Công dụng", indications, Colors.green),
                _coloredSection("Chống chỉ định", contraindications, Colors.redAccent),
                _coloredSection("Tác dụng phụ", sideEffects, Colors.orange),
                _coloredSection("Liều dùng", dosage, Colors.blue),
                _coloredSection("Thận trọng / Lưu ý", precautions, Colors.purple),
                _coloredSection("Tương tác thuốc", interactions, Colors.teal),
              ],
            ),
          );
        }).toList(),
      );
}
