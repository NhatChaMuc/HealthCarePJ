class AppConfig {
  // ⚙️ Địa chỉ backend của ngài
  static const String _ip = '172.17.11.4';
  static const String _port = '8081';

  /// URL gốc của API backend
  static const String baseUrl = 'http://$_ip:$_port/api';

  static const String auth = '$baseUrl/auth';
  static const String admin = '$baseUrl/admin';
  static const String ai = '$baseUrl/ai';
  static const String chat = '$baseUrl/chat';

  /// ✅ Public getter để file khác (như admin_service.dart) có thể dùng
  static String get ip => _ip;
}
