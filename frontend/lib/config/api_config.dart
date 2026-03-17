import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ── Environment ─────────────────────────────────────────────────────────────
  static String get env => dotenv.get('ENV', fallback: 'development');
  static bool get isDevelopment => env == 'development';

  // ── Base URLs ────────────────────────────────────────────────────────────────
  static String get baseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://10.135.222.46:8000/api');
  static String get authUrl => '$baseUrl/auth';
  static String get blogsUrl => '$baseUrl/blogs';

  // ── Settings ─────────────────────────────────────────────────────────────────
  static int get requestTimeout =>
      int.parse(dotenv.get('REQUEST_TIMEOUT', fallback: '30'));
  static int get pageSize => int.parse(dotenv.get('PAGE_SIZE', fallback: '10'));

  // ── Token Keys ───────────────────────────────────────────────────────────────
  static String get accessTokenKey =>
      dotenv.get('ACCESS_TOKEN_KEY', fallback: 'access_token');
  static String get refreshTokenKey =>
      dotenv.get('REFRESH_TOKEN_KEY', fallback: 'refresh_token');

  // ── Auth Endpoints ───────────────────────────────────────────────────────────
  static String get loginEndpoint => '$authUrl/login/';
  static String get registerEndpoint => '$authUrl/register/';
  static String get logoutEndpoint => '$authUrl/logout/';
  static String get refreshTokenEndpoint => '$authUrl/token/refresh/';
  static String get profileEndpoint => '$authUrl/profile/';
  static String get changePasswordEndpoint => '$authUrl/change-password/';

  // ── Blog Endpoints ───────────────────────────────────────────────────────────
  static String get blogsEndpoint => '$blogsUrl/';
  static String blogDetailEndpoint(int id) => '$blogsUrl/$id/';
  static String blogCommentEndpoint(int id) => '$blogsUrl/$id/add_comment/';
  static String get blogStatisticsEndpoint => '$blogsUrl/statistics/';

  // ── Headers ──────────────────────────────────────────────────────────────────
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) {
    return {...headers, 'Authorization': 'Bearer $token'};
  }

  // ── Security ─────────────────────────────────────────────────────────────────
  static void validateSecureConnection() {
    if (!isDevelopment && !baseUrl.startsWith('https://')) {
      throw Exception('Production API_BASE_URL must use HTTPS.');
    }
  }
}
