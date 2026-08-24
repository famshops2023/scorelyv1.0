// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

Future<void> main() async {
  final host = 'https://ip53vj9s.ap-southeast.insforge.app';
  try {
    final res = await http.get(Uri.parse('$host/'));
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Failed: $e');
  }
}
