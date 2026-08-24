// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final host = 'https://ip53vj9s.ap-southeast.insforge.app';
  final apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';

  final headers = {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  print('--- Testing Real SignUp ---');
  final email = 'test_${DateTime.now().millisecondsSinceEpoch}@scorely.com';
  final body = {
    'email': email,
    'password': 'password123',
  };

  try {
    final res = await http.post(
      Uri.parse('$host/api/auth/users'),
      headers: headers,
      body: jsonEncode(body),
    );
    print('SignUp status: ${res.statusCode}');
    print('SignUp response: ${res.body}');

    print('\n--- Testing Real SignIn ---');
    final loginRes = await http.post(
      Uri.parse('$host/api/auth/sessions'),
      headers: headers,
      body: jsonEncode(body),
    );
    print('SignIn status: ${loginRes.statusCode}');
    print('SignIn response: ${loginRes.body}');
  } catch (e) {
    print('Auth test failed: $e');
  }
}
