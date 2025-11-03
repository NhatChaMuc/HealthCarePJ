import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // 💡 IMPORT FILE MỚI

class AuthService {
  /// ⚙️ Backend base URL (Lấy từ AppConfig)
  static const String baseUrl = AppConfig.auth; // ✅ SỬA Ở ĐÂY

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  /// 📝 Đăng ký
  Future<String?> register(
    String fullName,
    String account,
    String password,
    String role,
    String roleLevel, // ✅ THÊM THAM SỐ NÀY
  ) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final res = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'fullName': fullName,
              'account': account,
              'username': account, // phòng khi BE dùng "username"
              'password': password,
              'role': role, // USER / DOCTOR / NURSE / ADMIN
              'roleLevel': roleLevel, // ✅ THÊM TRƯỜNG NÀY
            }),
          )
          .timeout(const Duration(seconds: 8));

      _log('Register', res);

      if (res.statusCode == 200 || res.statusCode == 201) return null; // ✅ Sửa: 201 cũng là thành công

      final body = _safeJson(res);
      return (body['error'] ??
              body['message'] ??
              'Đăng ký thất bại (${res.statusCode})')
          .toString();
    } on TimeoutException {
      return '⏱️ Server không phản hồi, thử lại sau.';
    } on http.ClientException {
      return '❌ Không thể kết nối tới server.';
    } catch (e) {
      return '⚠️ Lỗi không xác định: $e';
    }
  }

  /// 🔐 Đăng nhập
  /// Trả về:
  ///   { 'token': ..., 'role': ..., 'fullName': ... }  |  { 'error': '...' }
  Future<Map<String, dynamic>> login(String account, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final res = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              // Gửi cả 2 khóa để tương thích nhiều BE
              'account': account,
              'username': account,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      _log('Login', res);

      // Nếu bị chặn bởi Security Filter: 401/403 + body rỗng
      if (res.statusCode == 401) {
        final body = _safeJson(res);
        return {
          'error': body['error'] ??
              '401 Unauthorized: BE đang chặn /api/auth/login (chưa permitAll).'
        };
      }
      if (res.statusCode == 403) {
        final body = _safeJson(res);
        return {
          'error': body['error'] ?? '403 Forbidden: Không đủ quyền truy cập.'
        };
      }
      if (res.statusCode >= 500) {
        return {'error': 'Server lỗi (${res.statusCode}).'};
      }

      final body = _safeJson(res);

      // Chuẩn ApiResponse: {"message":"ok","data":{...}}
      if (res.statusCode == 200 &&
          (body['message']?.toString().toLowerCase() == 'ok' ||
              body['status']?.toString().toLowerCase() == 'ok')) {
        final data = (body['data'] is Map) ? body['data'] as Map : {};
        return {
          'token': data['token'],
          'role': data['role'],
          'fullName': data['fullName'],
        };
      }

      // Một số BE trả trực tiếp {token, role, ...}
      if (res.statusCode == 200 && body.isNotEmpty) {
        return {
          'token': body['token'],
          'role': body['role'],
          'fullName': body['fullName'] ?? body['name'] ?? body['full_name'],
        };
      }

      return {
        'error': body['error'] ??
            body['message'] ??
            'Đăng nhập thất bại (${res.statusCode})'
      };
    } on TimeoutException {
      return {'error': '⏱️ Server không phản hồi, thử lại sau.'};
    } on http.ClientException {
      return {'error': '❌ Không thể kết nối tới server.'};
    } catch (e) {
      return {'error': '⚠️ Lỗi không xác định: $e'};
    }
  }

  /// ---- Helpers ----
  void _log(String tag, http.Response res) {
    // In vừa status vừa raw & parsed để soi nhanh
    // (Tránh crash nếu body rỗng/không phải JSON)
    String raw;
    try {
      raw = utf8.decode(res.bodyBytes);
    } catch (_) {
      raw = res.body;
    }
    Map parsed = {};
    try {
      parsed = jsonDecode(raw) as Map;
    } catch (_) {}
    // ignore: avoid_print
    print('📡 [$tag] ${res.request?.url}');
    // ignore: avoid_print
    print('🛰️ [$tag] status: ${res.statusCode}');
    // ignore: avoid_print
    print('🧾 [$tag] raw body: $raw');
    // ignore: avoid_print
    print('📦 [$tag] parsed: $parsed');
  }

  Map<String, dynamic> _safeJson(http.Response res) {
    if (res.bodyBytes.isEmpty) return <String, dynamic>{};
    try {
      final text = utf8.decode(res.bodyBytes);
      final obj = jsonDecode(text);
      return (obj is Map<String, dynamic>) ? obj : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}