// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

const host = 'https://ip53vj9s.ap-southeast.insforge.app';
const apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';

final headers = {
  'apikey': apiKey,
  'Authorization': 'Bearer $apiKey',
  'Content-Type': 'application/json',
};

void main() async {
  print('\n=== Testing Query Syntax ===\n');

  final urls = [
    // PostgREST style
    '$host/api/database/records/teams?select=*',
    '$host/api/database/records/teams?id=eq.123',
    // NocoDB / other styles
    '$host/api/database/records/teams',
  ];

  for (final url in urls) {
    try {
      final res = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('${res.statusCode} — $url');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('list')) {
           print('   → Wrapper object found: ${data.keys.join(", ")}');
        }
      }
    } catch (e) {
      print('💥 Error: $e');
    }
    print('');
  }
}
