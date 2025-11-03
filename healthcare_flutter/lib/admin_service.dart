import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app_config.dart';

/// 🌟 AdminService: Chứa các hàm quản trị (tạo tài khoản bác sĩ, y tá, v.v.)
class AdminService {
  /// 🔗 URL gốc của API backend
  static const String _baseUrl = AppConfig.admin;

  String get baseUrl => _baseUrl;

  /// 🩺 Tạo tài khoản **Bác sĩ mới**
  Future<String> createDoctor({
    required String fullName,
    required String username,
    required String password,
    required String adminToken,
    required String specialty,
    required String department,
  }) async {
    final url = Uri.parse('$baseUrl/create-doctor'); // ✅ endpoint đúng

    return _postUser(
      url: url,
      fullName: fullName,
      username: username,
      password: password,
      adminToken: adminToken,
      successMessage: '✅ Tạo bác sĩ thành công.',
      // ✅ SỬA: Gửi specialty và department xuống hàm post chung
      specialty: specialty,
      department: department,
    );
  }

  /// 🧑‍⚕️ Tạo tài khoản **Y tá mới**
  Future<String> createNurse({
    required String fullName,
    required String username,
    required String password,
    required String adminToken,
    required String department,
  }) async {
    final url = Uri.parse('$baseUrl/create-nurse'); // ✅ endpoint đúng

    return _postUser(
      url: url,
      fullName: fullName,
      username: username,
      password: password,
      adminToken: adminToken,
      successMessage: '✅ Tạo y tá thành công.',
      // ✅ SỬA: Gửi department xuống hàm post chung
      department: department,
    );
  }

  /// 🧱 Hàm POST chung cho doctor/nurse
  Future<String> _postUser({
    required Uri url,
    required String fullName,
    required String username,
    required String password,
    required String adminToken,
    required String successMessage,
    // ✅ SỬA: Thêm các trường tùy chọn
    String? specialty,
    String? department,
  }) async {
    try {
      // ✅ SỬA: Xây dựng body động
      final Map<String, String> body = {
        'fullName': fullName.trim(),
        'username': username.trim(),
        'password': password.trim(),
      };

      // Thêm specialty nếu (là bác sĩ) và có giá trị
      if (specialty != null && specialty.isNotEmpty) {
        body['specialty'] = specialty.trim();
      }
      
      // Thêm department nếu có giá trị
      if (department != null && department.isNotEmpty) {
        body['department'] = department.trim();
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $adminToken',
            },
            // ✅ SỬA: Gửi body động đã được jsonEncode
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response, defaultSuccess: successMessage);
    } on TimeoutException {
      throw Exception('⏱️ Server không phản hồi (Timeout).');
    } on SocketException {
      throw Exception('📡 Không thể kết nối tới server (${AppConfig.ip}:8081).');
    } on http.ClientException {
      throw Exception('🚧 Lỗi kết nối HTTP Client.');
    } catch (e) {
      throw Exception('⚠️ Lỗi không xác định: $e');
    }
  }

  /// 🧩 Xử lý phản hồi HTTP (dùng chung)
  String _handleResponse(http.Response response,
      {required String defaultSuccess}) {
    final body = _tryDecode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return body['message'] ?? defaultSuccess;
      case 400:
        throw Exception(body['message'] ?? '❌ Dữ liệu không hợp lệ.');
      case 401:
        throw Exception('🔒 Token xác thực không hợp lệ hoặc đã hết hạn.');
      case 403:
        throw Exception('🚫 Bạn không có quyền thực hiện hành động này.');
      case 404:
        throw Exception('❌ API không tồn tại (404).');
      case 409:
        throw Exception(body['message'] ?? '⚠️ Username này đã tồn tại.');
      case 500:
        throw Exception(body['message'] ?? '💥 Lỗi máy chủ nội bộ (500).');
      default:
        throw Exception(body['message'] ?? '❌ Lỗi không xác định từ server.');
    }
  }

  /// 🔍 Decode JSON an toàn, tránh crash nếu server trả text thường
  Map<String, dynamic> _tryDecode(String raw) {
    try {
      return jsonDecode(utf8.decode(raw.codeUnits)) as Map<String, dynamic>;
    } catch (_) {
      return {'message': raw};
    }
  }
}
