import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

/// Simple enumeration for biological sex values.
enum Sex { MALE, FEMALE, OTHER }

/// A board for doctors, nurses and patients to view and edit their basic
/// personal information.  Allows editing full name, birthday and sex.  The
/// role is derived from the JWT on the server side and cannot be edited.
class InfoBoard extends StatefulWidget {
  /// The JWT bearer token used to authenticate requests.
  final String token;

  /// The role of the current user (e.g. DOCTOR, NURSE, PATIENT).
  /// Included here for completeness but the role is not editable.
  final String role;

  /// The full name of the current user as provided on login.
  /// Used to prefill the name field if no information exists on the server.
  final String fullName;

  const InfoBoard({
    super.key,
    required this.token,
    required this.role,
    required this.fullName,
  });

  @override
  State<InfoBoard> createState() => _InfoBoardState();
}

class _InfoBoardState extends State<InfoBoard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthday;
  Sex? _sex;
  bool _loading = false;
  bool _initializing = true;
  // Selected department (khoa) for the user. This field is required.
  String? _department;
  // List of departments available for selection. These can be customized or loaded from API.
  final List<String> _departments = [
    'Khoa Nội',
    'Khoa Ngoại',
    'Khoa Sản',
    'Khoa Nhi',
    'Khoa Tai Mũi Họng',
    'Khoa Da Liễu',
    'Khoa Hô Hấp',
    'Khoa Tiêu Hóa'
  ];

  @override
  void initState() {
    super.initState();
    // Prefill the full name with the value from login until we load from server.
    _nameController.text = widget.fullName;
    _loadInfo();
  }

  /// Fetch existing information from the backend for the current user.
  Future<void> _loadInfo() async {
    setState(() {
      _initializing = true;
    });
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/info/me');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      });
      if (resp.statusCode == 200 && resp.body.isNotEmpty && resp.body != 'null') {
        final data = json.decode(resp.body);
        setState(() {
          _nameController.text = data['fullName'] ?? _nameController.text;
          if (data['birthday'] != null) {
            try {
              _birthday = DateTime.parse(data['birthday']);
            } catch (_) {
              _birthday = null;
            }
          }
          if (data['sex'] != null) {
            final s = data['sex'].toString().toUpperCase();
            _sex = Sex.values.firstWhere(
              (e) => e.name == s,
              orElse: () => Sex.OTHER,
            );
          }
          if (data['department'] != null && data['department'].toString().isNotEmpty) {
            _department = data['department'];
            // If the department from backend isn't in our predefined list, add it so it can display.
            if (!_departments.contains(_department)) {
              _departments.add(_department!);
            }
          }
        });
      }
    } catch (e) {
      // ignore errors, leave defaults
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  /// Persist the edited information back to the backend.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _birthday == null ||
        _sex == null ||
        _department == null ||
        _department!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    final payload = {
      'fullName': _nameController.text.trim(),
      'birthday': _birthday!.toIso8601String().substring(0, 10),
      'sex': _sex!.name,
      'department': _department,
    };
    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/info/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Lưu thành công")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi ${resp.statusCode}: ${resp.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a spinner while we load existing info from the server.
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thông tin cá nhân",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Full name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Họ và tên",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Vui lòng nhập họ tên" : null,
            ),
            const SizedBox(height: 16),
            // Sex
            DropdownButtonFormField<Sex>(
              value: _sex,
              decoration: const InputDecoration(
                labelText: "Giới tính",
                border: OutlineInputBorder(),
              ),
              items: Sex.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sex = v),
              validator: (v) => v == null ? "Vui lòng chọn giới tính" : null,
            ),
            const SizedBox(height: 16),
            // Birthday
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final initialDate = _birthday ?? DateTime(now.year - 20, 1, 1);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(now.year - 120, 1, 1),
                  lastDate: now,
                );
                if (picked != null) {
                  setState(() {
                    _birthday = picked;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: _birthday == null
                        ? "Ngày sinh"
                        : "Ngày sinh: ${_birthday!.toLocal()}".split(' ').first,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Department / Khoa selection
            DropdownButtonFormField<String>(
              value: _department,
              decoration: InputDecoration(
                labelText: widget.role.toUpperCase() == 'PATIENT'
                    ? 'Vị trí khám-chữa bệnh'
                    : 'Vị trí công tác',
                border: const OutlineInputBorder(),
              ),
              items: _departments
                  .map((dept) => DropdownMenuItem(
                        value: dept,
                        child: Text(
                          dept,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _department = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng chọn khoa' : null,
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
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
                    : const Icon(Icons.save_alt, color: Colors.white),
                label: Text(
                  _loading ? "Đang lưu..." : "Lưu thông tin",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            // Display summary of entered information including department
            if (_birthday != null &&
                _sex != null &&
                _department != null &&
                _department!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8FB),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Thông tin đã lưu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Họ tên: ${_nameController.text}"),
                      Text("Giới tính: ${_sex!.name}"),
                      Text("Ngày sinh: ${_birthday!.toLocal()}"
                          .split(' ')
                          .first),
                      Text(
                        (widget.role.toUpperCase() == 'PATIENT'
                                ? 'Vị trí khám-chữa bệnh'
                                : 'Vị trí công tác') +
                            ": ${_department}",
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}