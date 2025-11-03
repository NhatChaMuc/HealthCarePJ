class AppConfig {

  // 1. Đọc biến 'API_URL' được tiêm vào bởi Vercel (lúc --dart-define)
  // 2. Nếu không tìm thấy (khi chạy local), nó sẽ dùng giá trị 'defaultValue'
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://172.17.11.4:8081/api', // IP local của bạn để debug
  );

  // 3. Mọi thứ còn lại sẽ tự động dùng baseUrl (đúng cho cả local và production)
  static const String auth = '$baseUrl/auth';
  static const String admin = '$baseUrl/admin';
  static const String ai = '$baseUrl/ai';
  static const String chat = '$baseUrl/chat';

  /// ✅ Public getter (file khác có thể vẫn cần)
  static String get ip => '172.17.11.4';
}