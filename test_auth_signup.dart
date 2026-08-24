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

  print('--- Testing Auth SignUp ---');
  final signupBody = {
    'email': 'test_${DateTime.now().millisecondsSinceEpoch}@scorely.com',
    'password': 'password123',
    'data': {
      'name': 'Test User',
    }
  };

  try {
    final res = await http.post(
      Uri.parse('$host/auth/v1/signup'),
      headers: headers,
      body: jsonEncode(signupBody),
    );
    print('SignUp status: ${res.statusCode}');
    print('SignUp response body: ${res.body}');
  } catch (e) {
    print('SignUp test failed: $e');
  }
}
