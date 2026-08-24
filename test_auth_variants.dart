// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final host = 'https://ip53vj9s.ap-southeast.insforge.app';
  final apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';

  final headers = {
    'apikey': apiKey,
    'Content-Type': 'application/json',
  };

  final endpoints = [
    '$host/api/auth/v1/signup',
    '$host/api/auth/signup',
    '$host/auth/signup',
    '$host/auth/v1/signup',
    '$host/user/signup',
  ];

  final body = jsonEncode({
    'email': 'test_${DateTime.now().millisecondsSinceEpoch}@scorely.com',
    'password': 'password123',
  });

  for (final url in endpoints) {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 5));
      print('${res.statusCode} - $url');
      if (res.statusCode != 404) {
        print('Response: ${res.body}');
      }
    } catch (e) {
      print('Failed $url: $e');
    }
  }
}
