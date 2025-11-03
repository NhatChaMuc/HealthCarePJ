import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // dùng AppConfig.admin

class ManageAccountsScreen extends StatefulWidget {
  final String adminToken;
  const ManageAccountsScreen({super.key, required this.adminToken});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  late Future<List<_Account>> _futureAccounts;
  String _roleFilter = 'ALL';
  final Set<String> _visiblePasswords = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureAccounts = _fetchAccounts();
  }

  // 🧩 Lấy danh sách tài khoản
  Future<List<_Account>> _fetchAccounts() async {
    final uri = Uri.parse('${AppConfig.admin}/users');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer ${widget.adminToken}',
      'Accept': 'application/json',
    });

    if (resp.statusCode != 200) {
      throw Exception('Load accounts failed (${resp.statusCode})');
    }

    final List data = json.decode(resp.body);
    final all = data.map((e) => _Account.fromJson(e)).toList();

    var list = all.where((u) => u.role != 'ADMIN').toList();

    if (_roleFilter != 'ALL') {
      list = list.where((u) => u.role == _roleFilter).toList();
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  Future<void> _refresh() async {
    setState(() => _futureAccounts = _fetchAccounts());
  }

  void _togglePassword(String id) {
    setState(() {
      if (_visiblePasswords.contains(id)) {
        _visiblePasswords.remove(id);
      } else {
        _visiblePasswords.add(id);
      }
    });
  }

  // 🔐 Đặt lại mật khẩu
  Future<void> _resetPassword(_Account acc) async {
    final newPassCtrl = TextEditingController();
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi mật khẩu', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${acc.fullName} (${acc.username})', style: GoogleFonts.inter()),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setS) => TextField(
                controller: newPassCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setS(() => obscure = !obscure),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '⚠️ Nên đặt mật khẩu mạnh (≥8 ký tự, có chữ hoa, số, ký tự đặc biệt).',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.orange[800]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );

    if (ok != true) return;

    final newPass = newPassCtrl.text.trim();
    if (newPass.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mật khẩu mới không được rỗng.')));
      return;
    }
    if (newPass.length < 6) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mật khẩu tối thiểu 6 ký tự.')));
      return;
    }

    final uri = Uri.parse('${AppConfig.admin}/users/${acc.id}/reset-password');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.adminToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'newPassword': newPass}),
    );

    if (!mounted) return;

    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
      _refresh();
    } else {
      final body = resp.body;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đổi mật khẩu thất bại (${resp.statusCode}) ${body.isNotEmpty ? "- $body" : ""}')));
    }
  }

  // 🗑️ Xoá tài khoản
  Future<void> _deleteAccount(_Account acc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xoá tài khoản', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Bạn có chắc muốn xoá "${acc.fullName}" (${acc.username}) không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );

    if (ok != true) return;

    final uri = Uri.parse('${AppConfig.admin}/users/${acc.id}');
    final resp = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.adminToken}',
        'Accept': 'application/json',
      },
    );

    if (!mounted) return;

    if (resp.statusCode == 200 || resp.statusCode == 204) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xoá tài khoản thành công.')));
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Xoá thất bại (${resp.statusCode}) ${resp.body}'),
      ));
    }
  }

  // 🧱 UI chính
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔎 Thanh công cụ
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc username…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  onChanged: (_) => _refresh(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: _roleFilter,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Tất cả vai trò')),
                    DropdownMenuItem(value: 'DOCTOR', child: Text('Doctor')),
                    DropdownMenuItem(value: 'NURSE', child: Text('Nurse')),
                    DropdownMenuItem(value: 'PATIENT', child: Text('Patient')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _roleFilter = v;
                      _futureAccounts = _fetchAccounts();
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),

        // 📋 Bảng tài khoản
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<_Account>>(
                future: _futureAccounts,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 40),
                        Center(child: Text('❌ ${snap.error}', style: GoogleFonts.inter())),
                      ],
                    );
                  }

                  final accounts = (snap.data ?? []);
                  if (accounts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 40),
                        Center(
                            child: Text('Không có tài khoản (đã loại ADMIN).',
                                style: GoogleFonts.inter())),
                      ],
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                      columns: const [
                        DataColumn(label: Text('HỌ VÀ TÊN')),
                        DataColumn(label: Text('USERNAME')),
                        DataColumn(label: Text('MẬT KHẨU')),
                        DataColumn(label: Text('VAI TRÒ')),
                        DataColumn(label: Text('HÀNH ĐỘNG')),
                      ],
                      rows: accounts.map((u) {
                        final visible = _visiblePasswords.contains(u.id);
                        return DataRow(cells: [
                          DataCell(Text(u.fullName)),
                          DataCell(Text(u.username)),
                          DataCell(Row(
                            children: [
                              Expanded(
                                child: Text(
                                  visible
                                      ? (u.password.isNotEmpty
                                          ? u.password
                                          : '(no password)')
                                      : '••••••••',
                                  style: GoogleFonts.inter(
                                      color: visible
                                          ? Colors.redAccent
                                          : Colors.black54),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  visible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: const Color(0xFF6B7280),
                                ),
                                tooltip: visible ? 'Ẩn password' : 'Hiện password',
                                onPressed: () => _togglePassword(u.id),
                              ),
                            ],
                          )),
                          DataCell(SizedBox(
                            width: 90,
                            child: Center(child: _buildRoleChip(u.role)),
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                tooltip: 'Đổi mật khẩu',
                                onPressed: () => _resetPassword(u),
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF6B7280)),
                              ),
                              IconButton(
                                tooltip: 'Xoá tài khoản',
                                onPressed: () => _deleteAccount(u),
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Color(0xFF6B7280)),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🟦 Hiển thị chip vai trò
  Widget _buildRoleChip(String role) {
    Color bg, text;
    switch (role) {
      case 'DOCTOR':
        bg = const Color(0xFFE0EFFF);
        text = const Color(0xFF0052CC);
        break;
      case 'NURSE':
        bg = const Color(0xFFE3FCEF);
        text = const Color(0xFF006644);
        break;
      case 'PATIENT':
        bg = const Color(0xFFEAE6FF);
        text = const Color(0xFF403294);
        break;
      default:
        bg = Colors.grey.shade200;
        text = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 70),
      child: Text(
        role,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

// 🧾 Model tài khoản
class _Account {
  final String id;
  final String fullName;
  final String username;
  final String password;
  final String role;

  _Account({
    required this.id,
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
  });

  factory _Account.fromJson(Map<String, dynamic> j) {
    return _Account(
      id: j['id']?.toString() ?? '',
      fullName: j['fullName'] ?? j['name'] ?? '',
      username: j['username'] ?? j['account'] ?? '',
      password: j['password'] ?? '',
      role: (j['role'] ?? '').toString().toUpperCase(),
    );
  }
}
