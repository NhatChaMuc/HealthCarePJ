// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import './app_config.dart';
import './patient.dart';

class ApiService {
  final String? token;
  final String? role; // ✅ Thêm role để biết người dùng hiện tại

  ApiService({this.token, this.role});

  static String get _aiBase => AppConfig.ai;
  static String get _base => AppConfig.baseUrl;
  static String get _adminBase => AppConfig.admin;

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// 🧠 Helper chọn đúng base URL cho API tùy vai trò
  String get _effectiveBase {
    if (role == 'ADMIN') return _adminBase; // 👑 Admin dùng /api/admin
    return _base; // 👨‍⚕️ Doctor / Nurse / Patient dùng /api
  }

  // 💊 AI: Tra cứu thuốc
  Future<List<dynamic>> searchDrug(String name) async {
    final url = Uri.parse('$_aiBase/drug-info-full');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'drug': name}),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      final items = data['items'];
      if (items is List) return items;
      throw Exception('Phản hồi không đúng định dạng');
    } else {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  // 🧑‍⚕️ Patients CRUD
  Future<List<Patient>> getPatients() async {
    final url = Uri.parse('${_effectiveBase}/patients'); // ✅ linh hoạt theo role
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final List list = decoded is List ? decoded : (decoded['data'] ?? []);
      return list.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Lỗi tải bệnh nhân: HTTP ${res.statusCode}');
  }

  Future<Patient> getPatient(String id) async { // ✅ đổi int -> String
    final url = Uri.parse('${_effectiveBase}/patients/$id');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final obj = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
      return Patient.fromJson(obj);
    }
    throw Exception('Không tìm thấy bệnh nhân #$id');
  }

  Future<Patient> createPatient(Map<String, dynamic> input) async {
    final url = Uri.parse('${_effectiveBase}/patients');
    final res = await http.post(url, headers: _headers(), body: jsonEncode(input));
    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final obj = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
      return Patient.fromJson(obj);
    }
    throw Exception('Tạo bệnh nhân thất bại: HTTP ${res.statusCode}');
  }

  Future<Patient> updatePatient(String id, Map<String, dynamic> input) async { // ✅ đổi int -> String
    final url = Uri.parse('${_effectiveBase}/patients/$id');
    final res = await http.put(url, headers: _headers(), body: jsonEncode(input));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final obj = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
      return Patient.fromJson(obj);
    }
    throw Exception('Cập nhật bệnh nhân thất bại: HTTP ${res.statusCode}');
  }

  Future<void> deletePatient(String id) async { // ✅ đổi int -> String
    final url = Uri.parse('${_effectiveBase}/patients/$id');
    final res = await http.delete(url, headers: _headers());
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Xoá bệnh nhân thất bại: HTTP ${res.statusCode}');
    }
  }
}
