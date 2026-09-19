const String appBaseUrl = 'http://yonnnn.miuntech.my.id:2084';

class ApiConfig {
  static String? _cachedBaseUrl;

  static String get baseUrl => _cachedBaseUrl ?? appBaseUrl;
  static String get baseUrl2 => _cachedBaseUrl ?? appBaseUrl;
  static String get baseUrl3 => _cachedBaseUrl ?? appBaseUrl;
  static String get baseUrl4 => _cachedBaseUrl ?? appBaseUrl;
  static String get mlbbUrl => _cachedBaseUrl ?? appBaseUrl;
  static String get tiktokBoosterUrl => _cachedBaseUrl ?? appBaseUrl;

  static Future<String> get baseUrlAsync async => baseUrl;

  static void setBaseUrl(String url) {
    _cachedBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
