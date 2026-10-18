class InsforgeConfig {
  static const String baseUrl = String.fromEnvironment(
    'INSFORGE_BASE_URL',
    defaultValue: 'https://ip53vj9s.ap-southeast.insforge.app',
  );

  static const String apiKey = String.fromEnvironment(
    'INSFORGE_API_KEY',
    defaultValue: 'ik_d23aa9a406864853f254a0722fc1e56b',
  );

  static String get recordsUrl => '$baseUrl/api/database/records';

  static Map<String, String> get headers => {
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  static Map<String, String> authHeaders([String? userToken]) {
    final token = (userToken != null && userToken.isNotEmpty) ? userToken : apiKey;
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }
}
