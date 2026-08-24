// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

Future<void> main() async {
  final host = 'https://ip53vj9s.ap-southeast.insforge.app';
  final apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';

  final headers = {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  print('--- Testing Auth Endpoint ---');
  try {
    final res = await http.get(
      Uri.parse('$host/auth/v1/settings'),
      headers: headers,
    );
    print('Auth settings status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Auth settings check failed: $e');
  }

  print('\n--- Testing database profiles table ---');
  try {
    final res = await http.get(
      Uri.parse('$host/api/database/records/profiles?select=*'),
      headers: headers,
    );
    print('Profiles status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Profiles check failed: $e');
  }
}
