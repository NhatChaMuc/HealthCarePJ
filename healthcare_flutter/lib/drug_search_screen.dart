import 'package:flutter/material.dart';
import 'api_service.dart';

class DrugSearchScreen extends StatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  State<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends State<DrugSearchScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();

  bool _loading = false;
  String? _error;
  List<dynamic> _items = [];

  // ================= TÌM KIẾM =================
  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });

    try {
      final items = await _api.searchDrug(q);
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= GIAO DIỆN =================
  @override
  Widget build(BuildContext context) {
    // ignore: prefer_const_declarations
    final primary = const Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tra cứu thuốc"),
        backgroundColor: primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.text.isEmpty ? null : _search,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Ô nhập từ khóa
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: "Nhập tên thuốc (ví dụ: Paracetamol)",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Tìm"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Thông báo lỗi
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("❌ Lỗi: $_error",
                    style: const TextStyle(color: Colors.red)),
              ),

            // Danh sách kết quả
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        _loading
                            ? "Đang tìm kiếm..."
                            : "Chưa có kết quả hiển thị",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = _items[i] as Map<String, dynamic>;
                        final ten = it['Tên thuốc']?.toString() ?? '—';
                        final hang = it['Hãng sản xuất']?.toString() ?? '—';
                        final tomtat = it['Tóm tắt bác sĩ']?.toString() ?? '';

                        return ListTile(
                          leading: const Icon(Icons.medication_outlined,
                              color: Colors.blue),
                          title: Text(
                            ten,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(hang),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ten,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        tomtat.isNotEmpty
                                            ? tomtat
                                            : "Không có thông tin chi tiết.",
                                        style:
                                            const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
